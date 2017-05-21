port module Ports exposing (..)

import Json.Encode exposing (Value)


type alias LibraryData =
    { library : String
    , hmac : String
    }


type alias MasterKey =
    String


type alias ElementId =
    String


type alias Library =
    { blob : String
    , libraryVersion : Int
    , apiVersion : Int
    , modified : Int
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


type alias ParseLibraryDataContent =
    { masterKey : Maybe MasterKey
    , libraryData : Maybe LibraryData
    }


type alias Password =
    { comment : String
    , password : String
    , title : String
    , url : String
    , username : String
    }


port parseLibraryData : ParseLibraryDataContent -> Cmd msg


port encryptLibraryData : EncryptLibraryDataContent -> Cmd msg


port copyPasswordToClipboard : ElementId -> Cmd msg


port notification : (Value -> msg) -> Sub msg


port loginSuccess : (Value -> msg) -> Sub msg


port uploadLibrary : (Value -> msg) -> Sub msg
