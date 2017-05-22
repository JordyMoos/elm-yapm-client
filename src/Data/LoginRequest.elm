module Data.LoginRequest exposing (..)


type alias LoginRequest =
    { masterKey : Maybe MasterKey
    , libraryData : Maybe Library.Library
    }
