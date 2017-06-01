module PageState.Auth.NewMasterKey exposing (..)


type alias Model =
    { state : State
    , newMasterKey : String
    , newMasterKeyRepeat : String
    }


type State
    = NewMasterKeyForm
    | ConfirmationForm
