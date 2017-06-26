module Data.User exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))
import Data.Library as Library
import Data.Password as Password


type alias User =
    { library : Library.Library
    , masterKey : String
    , passwords : List Password.Password
    }


decoder : Decoder User
decoder =
    decode User
        |> required "library" Library.decoder
        |> required "masterKey" Decode.string
        |> required "passwords" (Decode.list Password.decoder)
