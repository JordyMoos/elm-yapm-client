module Data.EncryptLibraryRequest exposing (..)

import Data.Library as Library
import Data.Password as Password
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias EncryptLibraryRequest =
    { oldMasterKey : String
    , oldLibrary : Library.Library
    , newMasterKey : String
    , passwords : List Password.Password
    }


encode : EncryptLibraryRequest -> Value
encode request =
    Encode.object
        [ "oldMasterKey" => Encode.string request.oldMasterKey
        , "oldLibrary" => Library.encode request.oldLibrary
        , "newMasterKey" => Encode.string request.Encode.string
        , "passwords" => Password.encode request.passwords
        ]
