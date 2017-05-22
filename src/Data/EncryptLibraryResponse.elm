module Data.EncryptLibraryResponse exposing (..)


type alias EncryptLibraryResponse =
    { oldHash : String
    , newHash : String
    , libraryData : Library.Library
    }
