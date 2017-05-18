port module Main exposing (main)

import Basics exposing (..)
import Html
import Time
import Mouse
import Model exposing (..)
import Msg exposing (..)
import Cmd exposing (..)
import Update exposing (..)
import View exposing (..)


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( subModel, subCmd ) =
            Unauth.init
    in
        ( Model flags (Unauthorized subModel), Cmd.map UnauthorizedMsg subCmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        Authorized _ ->
            Auth.subscriptions

        Unauthorized _ ->
            Unauth.subscriptions
