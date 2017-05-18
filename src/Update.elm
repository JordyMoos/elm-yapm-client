module Update exposing (update)

import Auth exposing (update)
import Cmd exposing (..)
import Html exposing (a)
import Model exposing (..)
import Msg exposing (..)
import NewMasterKey.Update exposing (update)
import Unauth exposing (update)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        toPage : (a -> Model) -> (b -> Msg) -> (b -> a -> ( a, Cmd b )) -> b -> a -> ( Model, Cmd Msg )
        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
                ( { model | state = toModel newModel }, Cmd.map toMsg newCmd )
    in
        case ( msg, model.state ) of
            ( AuthorizedMsg msg, Authorized authModel ) ->
                toPage Authorized AuthorizedMsg Auth.update msg authModel

            ( UnauthorizedMsg msg, Unauthorized autModel ) ->
                toPage Unauthorized UnauthorizedMsg Unauth.update msg unauthModel

            -- bips voor verkeerde msg in state
            ( _, _ ) ->
                model ! []
