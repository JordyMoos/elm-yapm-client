module PageState.Auth.NewMasterKey exposing (..)

import Html exposing (..)

type Msg
    = NoOp
    | IetsAnders


type alias MasterKey =
    String


type alias Model =
    { state : State
    , newMasterKey : MasterKey
    , newMasterKeyRepeat : MasterKey
    }


type State
    = NewMasterKeyForm
    | ConfirmationForm


init : Model
init =
    Model NewMasterKeyForm "" ""

view : Model -> Html Msg
view { state, newMasterKey, newMasterKeyRepeat } =
    div
        []
        [ text "yo dit is een newmasterkeymodal" ]
