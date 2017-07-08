module Views.Modal exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Dict exposing (Dict)


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
            [ text "🗙" ]
        , h4 [ id "modalHeader" ]
            [ text title ]
        ]


viewFormInput : String -> Dict String String -> String -> String -> (String -> String -> msg) -> List (Html msg)
viewFormInput dictName fields title inputType onInputMsg =
    let
        maybeFieldValue =
            Dict.get dictName fields
    in
        case maybeFieldValue of
            Just fieldValue ->
                [ label
                    [ for dictName ]
                    [ text title ]
                , input
                    [ attribute "type" inputType
                    , value fieldValue
                    , onInput (onInputMsg dictName)
                    , id dictName
                    ]
                    []
                ]

            Nothing ->
                []


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
