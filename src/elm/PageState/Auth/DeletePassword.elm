module PageState.Auth.DeletePassword exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Dict exposing (Dict)
import Views.Modal exposing (..)
import Util
import Data.Password as Password


type alias Model =
    { id : Int
    , password : Password.Password
    }


type Msg
    = NoOp
    | SubmitConfirmation
    | Close


type SupervisorCmd
    = None
    | Quit
    | DeletePassword Int


init : Int -> Password.Password -> Model
init =
    Model


update : Msg -> Model -> ( Model, Cmd Msg, SupervisorCmd )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none, None )

        SubmitConfirmation ->
            ( model, Cmd.none, DeletePassword model.id )

        Close ->
            ( model, Cmd.none, Quit )


view : Model -> Html Msg
view model =
    viewModalContainer
        Close
        NoOp
        [ viewModalHeader Close "Delete Confirmation"
        , div []
            [ p []
                [ text <| "Are you sure you want to delete entry for " ++ model.password.title ++ "?" ]
            ]
        , div []
            [ button [ onClick SubmitConfirmation ]
                [ i [ class "icon-trash" ] []
                , text "Delete"
                ]
            ]
        ]
