port module Ports exposing (..)


type alias LibraryData =
    { library : String
    , hmac : String
    }


type alias MasterKey =
    String


type alias ParseLibraryDataContent =
    { masterKey : Maybe MasterKey
    , libraryData : Maybe LibraryData
    }


port parseLibraryData : ParseLibraryDataContent -> Cmd msg


port error : (String -> msg) -> Sub msg


port passwords : (List String -> msg) -> Sub msg


port encryptLibraryData : EncryptLibraryDataContent -> Cmd msg


port uploadLibrary : (UploadLibraryContent -> msg) -> Sub msg


port copyPasswordToClipboard : ElementId -> Cmd msg
