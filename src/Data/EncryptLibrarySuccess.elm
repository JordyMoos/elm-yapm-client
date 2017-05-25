module Data.EncryptLibrarySuccess exposing (..)

import Data.Library as Library
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias EncryptLibrarySuccess =
    { oldHash : String
    , newHash : String
    , library : Library.Library
    }


decoder : Decoder EncryptLibrarySuccess
decoder =
    decode EncryptLibrarySuccess
        |> required "oldHash" Decode.string
        |> required "newHash" Decode.string
        |> required "library" Library.decoder


decodeFromJson : Value -> Maybe EncryptLibrarySuccess
decodeFromJson json =
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.andThen (Decode.decodeString decoder >> Result.toMaybe)
