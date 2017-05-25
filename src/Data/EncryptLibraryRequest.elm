module Data.EncryptLibraryRequest exposing (..)

import Data.Library as Library
import Data.Password as Password
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias EncryptLibraryRequest =
    { oldMasterKey : String
    , oldLibrary : Library.Library
    , newMasterKey : String
    , passwords : List Password.Password
    }
