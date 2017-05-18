module Model exposing (..)

import NewMasterKey.Model
import Auth
import Unauth


type PageState
    = Unauthorized Unauth.Model
    | Authorized Auth.Model


type alias Model =
    { config : Flags
    , state : PageState
    }


type alias Library =
    { blob : String
    , libraryVersion : Int
    , apiVersion : Int
    , modified : Int
    }


type alias ParseLibraryDataContent =
    { masterKey : Maybe MasterKey
    , libraryData : Maybe LibraryData
    }


type alias EncryptLibraryDataContent =
    { oldMasterKey : Maybe MasterKey
    , oldLibraryData : Maybe LibraryData
    , newMasterKey : Maybe MasterKey
    , passwords : List Password
    }


type alias UploadLibraryContent =
    { oldHash : String
    , newHash : String
    , libraryData : LibraryData
    }


type alias ElementId =
    String


type alias PasswordId =
    Int


type alias MasterKey =
    String


initModel : Flags -> Model
initModel flags =
    { config = flags
    , state = Unauth.initModel
    }
