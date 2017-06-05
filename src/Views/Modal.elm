module Views.Modal exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Dict exposing (Dict)


viewModalContainer : msg -> msg -> List (Html msg) -> Html msg
viewModalContainer closeMsg noopMsg html =
    div
        ((onSelfClickWithId "modal" closeMsg noopMsg) ++ [ class "modal visible-modal" ])
        [ div [ class "modal-dialog" ]
            [ div [ class "modal-content" ]
                html
            ]
        ]


viewModalHeader : msg -> String -> Html msg
viewModalHeader closeMsg title =
    div [ class "modal-header" ]
        [ button
            [ class "close"
            , onClick closeMsg
            , attribute "aria-hidden" "true"
            ]
            [ text "x" ]
        , h4 [ class "modal-title", id "modalHeader" ]
            [ text title ]
        ]


viewFormInput : String -> Dict String String -> String -> String -> (String -> String -> msg) -> Html msg
viewFormInput dictName fields title inputType onInputMsg =
    let
        maybeFieldValue =
            Dict.get dictName fields
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
                            , onInput (onInputMsg dictName)
                            , class "form-control"
                            , id dictName
                            ]
                            []
                        ]
                    ]

            Nothing ->
                text ""


onSelfClickWithId : String -> msg -> msg -> List (Attribute msg)
onSelfClickWithId elementId closeMsg noopMsg =
    [ id elementId
    , on "click" <|
        Decode.map
            (\msg ->
                if msg == elementId then
                    closeMsg
                else
                    noopMsg
            )
            (Decode.at [ "target", "id" ] Decode.string)
    ]
