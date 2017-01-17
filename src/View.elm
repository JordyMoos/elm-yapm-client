module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode

import Model exposing (..)
import Msg exposing (..)
import NewMasterKey.Msg as NewMasterKeyMsg
import NewMasterKey.View


view : Model -> Html Msg
view model =
  if model.isAuthenticated then
    viewManager model
  else
    viewUnAuthSection model


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
    , viewError model.error
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
                [ input [
                    id "filter"
                    , placeholder "Filter... <CTRL+E>"
                    , class "flter-control"
                    , onInput UpdateFilter
                  ]
                  []
                ]
            , text " "
            , button [ class "save btn", onClick EncryptLibrary ]
                [ i [ class "icon-floppy" ] []
                , text " Save"
                ]
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
        , viewPasswords model.filter model.passwords
        ]
    ]

passwordFilter : String -> WrappedPassword -> Bool
passwordFilter filter password =
  List.all (\subfilter -> String.contains subfilter <| String.toLower password.password.title) <| String.split " " filter


viewPasswords : String -> List WrappedPassword -> Html Msg
viewPasswords filter passwords =
  tbody [] (List.map viewPassword <| List.filter (passwordFilter <| String.toLower filter) passwords)


viewPassword : WrappedPassword -> Html Msg
viewPassword {password, id, isVisible} =
  tr [ Html.Attributes.id ("password-" ++ (toString id)) ]
    [ td [] [ text password.title ]
    , td [] [ viewObscuredField ("password-username-" ++ (toString id)) password.username isVisible ]
    , td [] [ viewObscuredField ("password-password-" ++ (toString id)) password.password isVisible ]
    , td [] [ div [ class "comment" ] [ text password.comment ] ]
    , td []
        [ a [ class "copyPassword", onClick (CopyPasswordToClipboard ("password-password-" ++ (toString id))) ]
            [ i [ class "icon-docs" ] [] ]
        , a [ class "toggleVisibility", onClick (TogglePasswordVisibility id) ]
            [ i [ class "icon-eye" ] [] ]
        , a [ class "editPassword" ]
            [ i [ class "icon-edit" ] [] ]
        , a [ class "deletePassword", onClick (AskDeletePassword id) ]
            [ i [ class "icon-trash" ] [] ]
        ]
    ]


viewObscuredField : String -> String -> Bool -> Html Msg
viewObscuredField fieldId message isVisible =
  div
    [ class (getPasswordVisibility isVisible)
    , id fieldId
    ]
    [ text message ]


getPasswordVisibility : Bool -> String
getPasswordVisibility isVisible =
  if isVisible then
    ""
  else
    "obscured"


viewModal : Model -> Html Msg
viewModal model =
  case model.modal of
    Just EditPassword ->
      text "Show exit password"

    Just NewPassword ->
      viewNewPasswordModal model

    Just NewMasterKey ->
      NewMasterKey.View.viewModal model

    Just NewMasterKeyConfirmation ->
      NewMasterKey.View.viewConfirmationModal model

    Just (DeletePasswordConfirmation id) ->
      List.filter (\password -> password.id == id) model.passwords
        |> List.head
        |> viewDeletePasswordConfirmation

    Nothing ->
      text ""


onSelfClickWithId : String -> List (Attribute Msg)
onSelfClickWithId elementId =
  [ id elementId
  , on "click" <|
      Decode.map
        (\msg ->
          if msg == elementId then
            CloseModal
          else
            NoOp
        )
        (Decode.at ["target", "id"] Decode.string)
  ]


viewModalContainer : List (Html Msg) -> Html Msg
viewModalContainer html =
  div
    ( onSelfClickWithId "modal" ++ [ class "modal visible-modal" ] )
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


viewDeletePasswordConfirmation : Maybe WrappedPassword -> Html Msg
viewDeletePasswordConfirmation password =
  case password of
    Just password ->
      viewModalContainer
        [ viewModalHeader "Delete Password"
        , viewDeletePasswordContent password
        , div [ class "modal-footer" ]
            [ a [ class "btn btn-default", onClick CloseModal ]
                [ text "No Cancel" ]
            , a [ class "btn btn-danger", onClick (ConfirmDeletePassword password.id) ]
                [ text "Yes Delete" ]
            ]
        ]

    Nothing ->
      text ""


viewDeletePasswordContent : WrappedPassword -> Html Msg
viewDeletePasswordContent password =
  div [ class "modal-body" ]
    [ p []
        [ text "Are you sure you want to delete this password?" ]
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
    --
    -- Off for now because it is just visual an no longer compatible with the viewFormInput function
    --
    -- [ viewFormInput "title" "Title" "text"
    -- , viewFormInput "URL" "URL" "text"
    -- , viewFormInput "username" "Username" "text"
    -- , viewFormInput "pass" "Password" "password"
    -- , viewFormInput "passRepeat" "Password Repeat" "password"
    -- , viewFormTextarea "comment" "Comment"
    -- ]
    []


viewFormInput : String -> String -> String -> String -> (String -> Msg) -> Html Msg
viewFormInput inputId title inputType inputValue onInputAction =
  div
    [ class "form-group" ]
    [ label
      [ class "col-sm-4 control-label", for inputId ]
      [ text title ]
    , div
      [ class "col-sm-8" ]
      [ input
        [ attribute "type" inputType
        , value inputValue
        , onInput onInputAction
        , class "form-control"
        , id inputId
        ]
        []
      ]
    ]


viewFormTextarea : String -> String -> Html Msg
viewFormTextarea inputId title =
  div [ class "form-group" ]
    [ label [ class "col-sm-4 control-label", for inputId ]
        [ text title ]
    , div [ class "col-sm-8" ]
        [ textarea [ class "form-control", id inputId ] [] ]
    ]
