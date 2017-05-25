module Data.EncryptLibraryRequest exposing (..)

import Data.Library as Library
import Data.Password as Password
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias EncryptLibraryRequest =
    { oldMasterKey : String
    , oldLibrary : Library.Library
    , newMasterKey : Maybe String
    , passwords : List Password.Password
    }
