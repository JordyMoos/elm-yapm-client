module NewMasterKey.View exposing (viewModal, viewConfirmationModal)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Dict exposing (Dict)

import Model exposing (..)
import NewMasterKey.Msg as NewMasterKeyMsg
import Msg exposing (Msg(MsgForNewMasterKey, CloseModal, NoOp))


viewModal : Model -> Html Msg
viewModal model =
  viewModalContainer
    [ viewModalHeader "New Master Key"
    , viewNewMasterKeyForm model
    , div [ class "modal-footer" ]
        [ a [ class "btn btn-primary", onClick (MsgForNewMasterKey NewMasterKeyMsg.Submit) ]
            [ i [ class "icon-attention" ] []
            , text "Save"
            ]
        ]
    ]


viewConfirmationModal : Model -> Html Msg
viewConfirmationModal model =
  viewModalContainer
    [ viewModalHeader "New Master Key Confirmation"
    , div [ class "modal-body" ]
      [ p []
        [ text "Are you sure you want to create a new master key?" ]
      ]
    , div [ class "modal-footer" ]
        [ a [ class "btn btn-default", onClick CloseModal ]
            [ text "No Cancel" ]
        , a [ class "btn btn-danger", onClick (MsgForNewMasterKey NewMasterKeyMsg.SubmitConfirmation) ]
            [ text "Yes Create" ]
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
            CloseModal
          else
            NoOp
        )
        (Decode.at ["target", "id"] Decode.string)
  ]


viewNewMasterKeyForm : Model -> Html Msg
viewNewMasterKeyForm model =
  Html.form [ class "modal-body form-horizontal" ]
    [ viewFormInput "key" model.newMasterKeyForm.fields "New Master Key" "password"
    , viewFormInput "repeat" model.newMasterKeyForm.fields "Master Key Repeat" "password"
    ]


viewFormInput : String -> Dict String String -> String -> String -> Html Msg
viewFormInput dictName fields title inputType =
  let
    maybeFieldValue = Dict.get dictName fields
  in
    case maybeFieldValue of
      Just fieldValue ->
        div
          [ class "form-group" ]
          [ label
            [ class "col-sm-4 control-label", for dictName ]
            [ text title ]
          , div
              [ class "col-sm-8" ]
              [ input
                [ attribute "type" inputType
                , value fieldValue
                , onInput (MsgForNewMasterKey << NewMasterKeyMsg.FieldInput dictName)
                , class "form-control"
                , id dictName
                ]
                []
              ]
          ]

      Nothing ->
        text ""
