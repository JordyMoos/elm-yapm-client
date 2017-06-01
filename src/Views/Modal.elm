module Views.Modal exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode


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
