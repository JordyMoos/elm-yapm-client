port module Main exposing (main)

import Data.Config exposing (Config)
import Data.User as User
import Html exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Mouse
import PageState.Auth as Auth
import PageState.Unauth as Unauth
import Ports
import Time


type PageState
    = Unauthorized Unauth.Model
    | Authorized Auth.Model


type alias Model =
    { config : Config
    , state : PageState
    }


type Msg
    = AuthorizedMsg Auth.Msg
    | UnauthorizedMsg Unauth.Msg


main : Program Config Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Config -> ( Model, Cmd Msg )
init config =
    let
        ( subModel, subCmd ) =
            Unauth.init config
    in
        ( Model config (Unauthorized subModel), Cmd.map UnauthorizedMsg subCmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        Authorized _ ->
            (Sub.map AuthorizedMsg Auth.subscriptions)

        Unauthorized _ ->
            (Sub.map UnauthorizedMsg Unauth.subscriptions)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.state ) of
        ( AuthorizedMsg subMsg, Authorized subModel ) ->
            let
                ( authModel, authCmd, supervisorCmd ) =
                    Auth.update subMsg subModel

                ( newModel, newCmd ) =
                    case supervisorCmd of
                        Auth.None ->
                            ( Authorized authModel, Cmd.map AuthorizedMsg authCmd )

                        Auth.Quit ->
                            let
                                ( unauthModel, unauthCmd ) =
                                    Unauth.init model.config
                            in
                                ( Unauthorized unauthModel, (Cmd.map UnauthorizedMsg unauthCmd) )
            in
                ( { model | state = newModel }, newCmd )

        ( UnauthorizedMsg subMsg, Unauthorized subModel ) ->
            let
                ( unauthModel, unauthCmd, supervisorCmd ) =
                    Unauth.update subMsg subModel

                ( newModel, newCmd ) =
                    case supervisorCmd of
                        Unauth.None ->
                            ( Unauthorized unauthModel, Cmd.map UnauthorizedMsg unauthCmd )

                        Unauth.Login user ->
                            let
                                ( authModel, authCmd ) =
                                    Auth.init model.config user
                            in
                                ( Authorized authModel, (Cmd.map AuthorizedMsg authCmd) )
            in
                ( { model | state = newModel }, newCmd )

        -- bips for wrong message in current state
        ( _, _ ) ->
            model ! []


view : Model -> Html Msg
view model =
    case model.state of
        Unauthorized unauth ->
            Unauth.view unauth |> Html.map UnauthorizedMsg

        Authorized auth ->
            Auth.view auth |> Html.map AuthorizedMsg
