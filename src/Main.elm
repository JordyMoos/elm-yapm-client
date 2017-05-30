port module Main exposing (main)

import Basics exposing (..)
import Html exposing (..)
import Time
import Mouse
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import PageState.Auth as Auth
import PageState.Unauth as Unauth
import Data.Config exposing (Config)
import Ports
import Data.User as User


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
    | SetUser (Maybe User.User)


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
            Sub.batch [ (Sub.map UnauthorizedMsg Unauth.subscriptions), Sub.map SetUser loginSuccess ]


loginSuccess : Sub (Maybe User.User)
loginSuccess =
    Ports.loginSuccess (Decode.decodeValue User.decoder >> Result.toMaybe)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        toPage : (a -> PageState) -> (b -> Msg) -> (b -> a -> ( a, Cmd b )) -> b -> a -> ( Model, Cmd Msg )
        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd, supervisorMsgs ) =
                    subUpdate subMsg subModel
            in
                ( { model | state = toModel newModel }, Cmd.map toMsg newCmd )
    in
        case ( msg, model.state ) of
            ( SetUser (Just user), _ ) ->
                let
                    ( authModel, authCmd ) =
                        Auth.init model.config user
                in
                    ( { model | state = Authorized authModel }, (Cmd.map AuthorizedMsg authCmd) )

            ( AuthorizedMsg (Auth.Logout), Authorized authModel ) ->
                let
                    ( newModel, newCmd ) =
                        Unauth.init model.config
                in
                    ( { model | state = Unauthorized newModel }, (Cmd.map UnauthorizedMsg newCmd) )

            ( AuthorizedMsg msg, Authorized authModel ) ->
                toPage Authorized AuthorizedMsg Auth.update msg authModel

            ( UnauthorizedMsg msg, Unauthorized unauthModel ) ->
                toPage Unauthorized UnauthorizedMsg Unauth.update msg unauthModel

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
