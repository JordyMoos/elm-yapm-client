module NewMasterKey.View exposing (viewModal, viewConfirmationModal)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode

import Model exposing (..)
import NewMasterKey.Msg exposing (..)
import Msg as MainMsg


viewModal : Model -> Html MainMsg.Msg
viewModal model =
  viewNewMasterKeyModal model
    |> Html.map MainMsg.MsgForNewMasterKey


viewConfirmationModal : Model -> Html MainMsg.Msg
viewConfirmationModal model =
  viewNewMasterKeyConfirmationModal
    |> Html.map MainMsg.MsgForNewMasterKey


viewNewMasterKeyModal : Model -> Html Msg
viewNewMasterKeyModal model =
  viewModalContainer
    [ viewModalHeader "New Master Key"
    , viewNewMasterKeyForm model
    , div [ class "modal-footer" ]
        [ a [ class "btn btn-primary", onClick Submit ]
            [ i [ class "icon-attention" ] []
            , text "Save"
            ]
        ]
    ]


viewModalHeader : String -> Html Msg
viewModalHeader title =
  div [ class "modal-header" ]
      [ button
          [ class "close"
          , onClick Close
          , attribute "aria-hidden" "true"
          ]
          [ text "x" ]
      , h4 [ class "modal-title", id "modalHeader" ]
          [ text title ]
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


onSelfClickWithId : String -> List (Attribute Msg)
onSelfClickWithId elementId =
  [ id elementId
  , on "click" <|
      Decode.map
        (\msg ->
          if msg == elementId then
            Close
          else
            NoOp
        )
        (Decode.at ["target", "id"] Decode.string)
  ]


viewNewMasterKeyForm : Model -> Html Msg
viewNewMasterKeyForm model =
  Html.form [ class "modal-body form-horizontal" ]
    [ viewFormInput "key" "New Master Key" "password" model.newMasterKeyForm.masterKey KeyInput
    , viewFormInput "keyRepeat" "Master Key Repeat" "password" model.newMasterKeyForm.masterKeyRepeat RepeatInput
    ]


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


viewNewMasterKeyConfirmationModal : Html Msg
viewNewMasterKeyConfirmationModal =
  viewModalContainer
    [ viewModalHeader "New Master Key Confirmation"
    , div [ class "modal-body" ]
      [ p []
        [ text "Are you sure you want to create a new master key?" ]
      ]
    , div [ class "modal-footer" ]
        [ a [ class "btn btn-default", onClick Close ]
            [ text "No Cancel" ]
        , a [ class "btn btn-danger", onClick SubmitConfirmation ]
            [ text "Yes Create" ]
        ]
    ]
