module Data.LoginRequest exposing (..)

import Data.Library as Library
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias LoginRequest =
    { masterKey : String
    , library : Library.Library
    }


encode : LoginRequest -> Value
encode request =
    Encode.object
        [ "masterKey" => Encode.string request.masterKey
        , "library" => Library.encode request.library
        ]
