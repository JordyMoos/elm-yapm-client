module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Model exposing (..)
import Msg exposing (..)
import NewMasterKey.Msg as NewMasterKeyMsg
import NewMasterKey.View
import Auth
import Unauth


view : Model -> Html Msg
view model =
    case model.state of
        Unauthorized unauth ->
            Unauth.view ( model.config, unauth ) |> Html.map Unauthorized

        Authorized auth ->
            HtAuth.view ( model.config, auth ) |> Html.map Authorized
