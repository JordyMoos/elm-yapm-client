port module Main exposing (..)

import Basics exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode


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


initModel : Model
initModel =
  Model "" Nothing False Nothing Nothing Nothing


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


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    DownloadLibrary ->
      (model, downloadLibraryCmd)

    NewLibrary (Ok newLibraryData) ->
      ({ model | libraryData = Just newLibraryData }, Cmd.none)

    NewLibrary (Err _) ->
      ({ model | error = Just "Fetching library failed" }, Cmd.none)

    SetMasterKeyInput masterKeyInput ->
      ({ model | masterKeyInput = masterKeyInput }, Cmd.none)

    SubmitAuthForm ->
      let
        masterKey = Just model.masterKeyInput
        masterKeyInput = ""
        newModel = { model | masterKey = masterKey, masterKeyInput = masterKeyInput}
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


-- decodeResponse : Decode.Decoder Library
-- decodeResponse =
--   Decode.at ["hmac"] Decode.string


decodeLibraryData =
  Decode.map2 LibraryData (Decode.field "library" Decode.string) (Decode.field "hmac" Decode.string)


decodeLibrary =
  Decode.map4 Library (Decode.field "blob" Decode.string) (Decode.field "library_version" Decode.int) (Decode.field "api_version" Decode.int) (Decode.field "modified" Decode.int)


decryptLibraryIfPossibleCmd : Model -> Cmd Msg
decryptLibraryIfPossibleCmd model =
  if areDecryptRequirementsMet model then
    parseLibraryData (ParseLibraryDataContent model.masterKey model.libraryData)
  else
    Cmd.none


areDecryptRequirementsMet : Model -> Bool
areDecryptRequirementsMet model =
  let
    unMetRequirements = [ maybeIsNothing model.masterKey, maybeIsNothing model.libraryData ]
      |> List.filter (\value -> value)
  in
    List.length unMetRequirements == 0


maybeIsNothing : Maybe a -> Bool
maybeIsNothing maybe =
  case maybe of
    Nothing ->
      True
    Just _ ->
      False


maybeHasValue : Maybe a -> Bool
maybeHasValue maybe =
  not (maybeIsNothing maybe)


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
        [ input [ placeholder "master key", onInput SetMasterKeyInput, value model.masterKeyInput, class "form-control", id "encryptionKey" ] []
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
            , button [ class "newPassword btn" ]
                [ i [ class "icon-plus" ] []
                , text " New Password"
                ]
            , button [ class "newMasterKey btn" ]
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
  text ""


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
      div [] (List.map viewPassword passwords)

    Nothing ->
      text ""


viewPassword : Password -> Html Msg
viewPassword password =
  p [] [ text (password.title ++ " - " ++ password.username) ]
