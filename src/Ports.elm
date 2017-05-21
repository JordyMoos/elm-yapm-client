port module Ports exposing (..)

import Json.Encode exposing (Value)


type alias MasterKey =
    String


type alias ElementId =
    String


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


port parseLibraryData : ParseLibraryDataContent -> Cmd msg


port encryptLibraryData : EncryptLibraryDataContent -> Cmd msg


port copyPasswordToClipboard : ElementId -> Cmd msg


port notification : (Value -> msg) -> Sub msg


port loginSuccess : (Value -> msg) -> Sub msg


port uploadLibrary : (Value -> msg) -> Sub msg
