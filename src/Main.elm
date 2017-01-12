port module Main exposing (..)

import Basics exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Maybe.Extra exposing (isNothing)


apiEndPoint = "http://localhost:8001"


main : Program Never Model Msg
main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


type alias Model =
  { masterKeyInput : String
  , masterKey : Maybe String
  , isDownloading : Bool
  , libraryData : Maybe LibraryData
  , error : Maybe String
  , passwords : Maybe (List Password)
  , modal : Maybe Modal
  }


type alias Library =
  { blob : String
  , libraryVersion : Int
  , apiVersion : Int
  , modified : Int
  }


type alias LibraryData =
  { library : String
  , hmac : String
  }


type alias ParseLibraryDataContent =
  { masterKey : Maybe String
  , libraryData : Maybe LibraryData
  }


type alias Password =
  { comment : String
  , password : String
  , title : String
  , url : String
  , username : String
  }


type Modal
  = EditPassword
  | NewPassword
  | NewMasterKey


initModel : Model
initModel =
  Model "" Nothing False Nothing Nothing Nothing Nothing


init : (Model, Cmd Msg)
init =
  doDownloadLibrary initModel


doDownloadLibrary : Model -> (Model, Cmd Msg)
doDownloadLibrary model =
  ({ model | isDownloading = True }, downloadLibraryCmd)


type Msg
  = DownloadLibrary
  | NewLibrary (Result Http.Error LibraryData)
  | SetMasterKeyInput String
  | SubmitAuthForm
  | SetError String
  | ClearError
  | SetPasswords (List Password)
  | Logout
  | ShowNewPasswordModal
  | ShowNewMasterKeyModal
  | CloseModal


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    DownloadLibrary ->
      (model, downloadLibraryCmd)

    NewLibrary (Ok newLibraryData) ->
      let
        newModel = { model | libraryData = Just newLibraryData }
      in
        ( newModel, decryptLibraryIfPossibleCmd newModel )

    NewLibrary (Err _) ->
      ({ model | error = Just "Fetching library failed" }, Cmd.none)

    SetMasterKeyInput masterKeyInput ->
      ({ model | masterKeyInput = masterKeyInput }, Cmd.none)

    SubmitAuthForm ->
      let
        masterKey = Just model.masterKeyInput
        masterKeyInput = ""
        newModel = { model | masterKey = masterKey, masterKeyInput = masterKeyInput }
      in
        ( newModel, decryptLibraryIfPossibleCmd newModel )

    SetError error ->
      ({ model | error = Just error }, Cmd.none )

    ClearError ->
      ({ model | error = Nothing }, Cmd.none )

    SetPasswords passwords ->
      ({ model | passwords = Just passwords }, Cmd.none )

    Logout ->
      ({ model | passwords = Nothing, masterKey = Nothing }, Cmd.none )

    ShowNewPasswordModal ->
      ({ model | modal = Just NewPassword }, Cmd.none )

    ShowNewMasterKeyModal ->
      ({ model | modal = Just NewMasterKey }, Cmd.none )

    CloseModal ->
      ({ model | modal = Nothing }, Cmd.none )


port parseLibraryData : ParseLibraryDataContent -> Cmd msg

port error : (String -> msg) -> Sub msg

port passwords : (List Password -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ error SetError
    , passwords SetPasswords
    ]


downloadLibraryCmd : Cmd Msg
downloadLibraryCmd =
  Http.send NewLibrary (Http.get apiEndPoint decodeLibraryData)


decodeLibraryData =
  Decode.map2 LibraryData (Decode.field "library" Decode.string) (Decode.field "hmac" Decode.string)


decryptLibraryIfPossibleCmd : Model -> Cmd Msg
decryptLibraryIfPossibleCmd model =
  if areDecryptRequirementsMet model then
    parseLibraryData (ParseLibraryDataContent model.masterKey model.libraryData)
  else
    Cmd.none


areDecryptRequirementsMet : Model -> Bool
areDecryptRequirementsMet model =
  let
    unMetRequirements = [ isNothing model.masterKey, isNothing model.libraryData ]
      |> List.filter (\value -> value)
  in
    List.length unMetRequirements == 0


view : Model -> Html Msg
view model =
  case model.passwords of
    Nothing ->
      viewUnAuthSection model

    Just _ ->
      viewManager model


viewUnAuthSection : Model -> Html Msg
viewUnAuthSection model =
  section
    [ id "unauthorized" ]
    [ div
       [ id "welcome" ]
       [ h1 [] [ text "Online Password Manager" ]
       , viewLoginForm model
       ]
    ]


viewLoginForm : Model -> Html Msg
viewLoginForm model =
  div
    []
    [ Html.form
        [ onSubmit SubmitAuthForm, class "well form-inline", id "decrypt" ]
        [ input
            [ placeholder "master key"
            , onInput SetMasterKeyInput
            , value model.masterKeyInput
            , class "form-control"
            , id "encryptionKey"
            , autocomplete False
            , attribute "type" "password"
            ]
            []
        , button
            [ class "btn" ]
            [ i [ class "icon-lock-open" ] []
            , text " Decrypt"
            ]
        ]
    , viewError model.error
    ]


viewLibraryData : Maybe LibraryData -> Html Msg
viewLibraryData libraryData =
  case libraryData of
    Just data ->
      p [] [ text data.library ]

    Nothing ->
      text ""


viewError : Maybe String -> Html Msg
viewError error =
  case error of
    Just message ->
      div []
        [ text "Error: "
        , text message
        , text " "
        , button [ onClick ClearError ] [ text "[x]" ]
        ]

    Nothing ->
      div [] [ text "[No Error]" ]


viewManager : Model -> Html Msg
viewManager model =
  section [ id "authorized" ]
    [ viewNavBar model
    , viewPasswordTable model
    , viewModal model
    ]


viewNavBar : Model -> Html Msg
viewNavBar model =
  nav [ class "navbar navbar-default navbar-fixed-top", attribute "role" "navigation" ]
    [ div [ class "navbar-header" ]
        [ a [ class "navbar-brand" ]
            [ text "Passwords" ] ]
    , div [ class "navbar" ]
        [ div [ class "navbar-form navbar-right", attribute "role" "form" ]
            [ div [ class "form-group" ]
                [ input [ id "filter", placeholder "Filter... <CTRL+E>", class "flter-control" ] [] ]
            , text " "
            , button [ class "newPassword btn", onClick ShowNewPasswordModal ]
                [ i [ class "icon-plus" ] []
                , text " New Password"
                ]
            , button [ class "newMasterKey btn", onClick ShowNewMasterKeyModal ]
                [ i [ class "icon-wrench" ] []
                , text " Change Master Key"
                ]
            , button [ class "logout btn", onClick Logout ]
                [ i [ class "icon-lock-open" ] []
                , text " Logout"
                ]
            ]
        ]
    ]


viewPasswordTable : Model -> Html Msg
viewPasswordTable model =
  div [ class "wide-container" ]
    [ table [ class "table table-striped", id "overview" ]
        [ thead []
            [ tr []
                [ th [] [ text "Title" ]
                , th [] [ text "Username" ]
                , th [] [ text "Password" ]
                , th [] [ text "Comment" ]
                , th [] [ text "Actions" ]
                ]
            ]
        , viewPasswords model.passwords
        ]
    ]


viewManagerDump : Model -> Html Msg
viewManagerDump model =
  div []
    [ button [ onClick Logout ] [ text "Logout" ]
    , viewPasswords model.passwords
    ]


viewPasswords : Maybe (List Password) -> Html Msg
viewPasswords passwords =
  case passwords of
    Just passwords ->
      tbody [] (List.map viewPassword passwords)

    Nothing ->
      tbody [] []


viewPassword : Password -> Html Msg
viewPassword password =
  tr []
    [ td [] [ text password.title ]
    , td [] [ div [ class "obscured" ] [ text password.username ] ]
    , td [] [ div [ class "obscured" ] [ text password.password ] ]
    , td [] [ div [ class "comment" ] [ text password.comment ] ]
    , td []
        [ a [ class "copyPassword" ]
            [ i [ class "icon-docs" ] [] ]
        , a [ class "toggleVisibility" ]
            [ i [ class "icon-eye" ] [] ]
        , a [ class "editPassword" ]
            [ i [ class "icon-edit" ] [] ]
        , a [ class "deletePassword" ]
            [ i [ class "icon-trash" ] [] ]
        ]
    ]


viewModal : Model -> Html Msg
viewModal model =
  case model.modal of
    Just EditPassword ->
      text "Show exit password"

    Just NewPassword ->
      viewNewPasswordModal model

    Just NewMasterKey ->
      viewNewMasterKeyModal model

    Nothing ->
      text ""


viewModalContainer : List (Html Msg) -> Html Msg
viewModalContainer html =
  div [ class "modal visible-modal", id "modal" ]
    [ div [ class "modal-dialog" ]
        [ div [ class "modal-content" ]
            html
        ]
    ]


viewModalHeader : String -> Html Msg
viewModalHeader title =
  div [ class "modal-header" ]
      [ button
          [ class "close"
          , onClick CloseModal
          , attribute "aria-hidden" "true"
          ]
          [ text "x" ]
      , h4 [ class "modal-title", id "modalHeader" ]
          [ text title ]
      ]


viewNewPasswordModal : Model -> Html Msg
viewNewPasswordModal model =
  viewModalContainer
    [ viewModalHeader "New Password"
    , viewNewPasswordForm model
    , div [ class "modal-footer" ]
        [ a [ class "btn btn-default" ]
            [ i [ class "icon-shuffle" ] []
            , text "Random Password"
            ]
        , a [ class "btn btn-primary" ]
            [ i [ class "icon-floppy" ] []
            , text "Save"
            ]
        ]
    ]


viewNewPasswordForm : Model -> Html Msg
viewNewPasswordForm model =
  Html.form [ class "modal-body form-horizontal" ]
    [ viewFormInput "title" "Title" "text"
    , viewFormInput "URL" "URL" "text"
    , viewFormInput "username" "Username" "text"
    , viewFormInput "pass" "Password" "password"
    , viewFormInput "passRepeat" "Password Repeat" "password"
    , viewFormTextarea "comment" "Comment"
    ]


viewNewMasterKeyModal : Model -> Html Msg
viewNewMasterKeyModal model =
  viewModalContainer
    [ viewModalHeader "New Master Key"
    , viewNewMasterKeyForm model
    , div [ class "modal-footer" ]
        [ a [ class "btn btn-primary" ]
            [ i [ class "icon-attention" ] []
            , text "Save"
            ]
        ]
    ]


viewNewMasterKeyForm : Model -> Html Msg
viewNewMasterKeyForm model =
  Html.form [ class "modal-body form-horizontal" ]
    [ viewFormInput "key" "New Master Key" "password"
    , viewFormInput "keyRepeat" "Master Key Repeat" "password"
    ]


viewFormInput : String -> String -> String -> Html Msg
viewFormInput inputId title inputType =
  div [ class "form-group" ]
    [ label [ class "col-sm-4 control-label", for inputId ]
        [ text title ]
    , div [ class "col-sm-8" ]
        [ input [ attribute "type" inputType, class "form-control", id inputId ] [] ]
    ]


viewFormTextarea : String -> String -> Html Msg
viewFormTextarea inputId title =
  div [ class "form-group" ]
    [ label [ class "col-sm-4 control-label", for inputId ]
        [ text title ]
    , div [ class "col-sm-8" ]
        [ textarea [ class "form-control", id inputId ] [] ]
    ]
