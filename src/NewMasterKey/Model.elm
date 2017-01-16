module NewMasterKey.Model exposing (..)


type alias Model = MasterKeyForm


type alias MasterKeyForm =
  { masterKey : String
  , masterKeyRepeat : String
  }


initModel : MasterKeyForm
initModel =
  MasterKeyForm "" ""
