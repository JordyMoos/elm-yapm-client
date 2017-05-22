module Data.EncryptLibraryRequest exposing (..)


type alias EncryptLibraryDataContent =
    { oldMasterKey : Maybe MasterKey
    , oldLibraryData : Maybe Library.Library
    , newMasterKey : Maybe MasterKey
    , passwords : List Password
    }
