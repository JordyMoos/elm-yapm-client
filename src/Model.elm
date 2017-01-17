module Model exposing (..)

import NewMasterKey.Model


type alias Flags =
  { apiEndPoint : String
  , localStorageKey : String
  , maxIdleTime : Int
  }


type alias Model =
  { config : Flags
  , masterKeyInput : String
  , masterKey : Maybe MasterKey
  , isDownloading : Bool
  , libraryData : Maybe LibraryData
  , error : Maybe String
  , passwords : (List WrappedPassword)
  , isAuthenticated : Bool
  , modal : Maybe Modal
  , idleTime : Int
  , uid : Int
  , newMasterKeyForm : NewMasterKey.Model.Model
  , filter : String
  }


type alias Library =
  { blob : String
  , libraryVersion : Int
  , apiVersion : Int
  , modified : Int
  }


type alias LibraryData =
  { library : String
  , hmac : String
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


type alias Password =
  { comment : String
  , password : String
  , title : String
  , url : String
  , username : String
  }


type alias WrappedPassword =
  { password : Password
  , id : Int
  , isVisible : Bool
  }


type Modal
  = EditPassword
  | NewPassword
  | NewMasterKey
  | NewMasterKeyConfirmation
  | DeletePasswordConfirmation Int


type alias ElementId = String


type alias PasswordId = Int


type alias MasterKey = String


initModel : Flags -> Model
initModel flags =
  { config = flags
  , masterKeyInput = ""
  , masterKey = Nothing
  , isDownloading = False
  , libraryData = Nothing
  , error = Nothing
  , passwords = []
  , isAuthenticated = False
  , modal = Nothing
  , idleTime = 0
  , uid = 0
  , newMasterKeyForm = NewMasterKey.Model.initModel
  , filter = ""
  }
