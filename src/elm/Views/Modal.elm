module Views.Modal exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Dict exposing (Dict)
import Util


viewModalContainer : msg -> msg -> List (Html msg) -> Html msg
viewModalContainer closeMsg noopMsg html =
    div ((onSelfClickWithId "modal" closeMsg noopMsg) ++ [ class "modal-container" ])
        [ div [ class "modal" ] html ]


viewModalHeader : msg -> String -> Html msg
viewModalHeader closeMsg title =
    span []
        [ button
            [ class "close"
            , onClick closeMsg
            , attribute "aria-hidden" "true"
            ]
            [ text "x" ]
        , h4 [ id "modalHeader" ]
            [ text title ]
        ]


viewDefaultFormInput : List (Html msg) -> String -> Dict String String -> String -> String -> (String -> String -> msg) -> Html msg
viewDefaultFormInput additionalHtmlList dictName fields title inputType onInputMsg =
    let
        maybeFieldValue =
            Dict.get dictName fields
    in
        case maybeFieldValue of
            Just fieldValue ->
                div
                    []
                    [ label
                        [ for dictName ]
                        [ text title ]
                    , div
                        []
                        (List.append
                            [ input
                                [ attribute "type" inputType
                                , value fieldValue
                                , onInput (onInputMsg dictName)
                                , id dictName
                                ]
                                []
                            ]
                            additionalHtmlList
                        )
                    ]

            Nothing ->
                text ""


viewCopyPasswordFormInput : msg -> String -> Dict String String -> String -> String -> (String -> String -> msg) -> Html msg
viewCopyPasswordFormInput onClickMsg dictName fields title inputType onInputMsg =
    viewDefaultFormInput
        [ a
            [ class "copyable copyPassword"
            , attribute "data-clipboard-text" <| Util.dictGetWithDefault fields "" dictName
            , onClick onClickMsg
            ]
            [ i [ class "icon-docs" ] [] ]
        ]
        dictName
        fields
        title
        inputType
        onInputMsg


viewFormInput : String -> Dict String String -> String -> String -> (String -> String -> msg) -> Html msg
viewFormInput =
    viewDefaultFormInput []


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
