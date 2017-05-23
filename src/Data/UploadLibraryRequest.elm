module Data.UploadLibraryRequest exposing (..)

import Data.Library as Library


type alias UploadLibraryRequest =
    { oldHash : String
    , newHash : String
    , libraryData : Library.Library
    }
