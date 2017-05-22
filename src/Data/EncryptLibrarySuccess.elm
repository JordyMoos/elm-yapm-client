module Data.EncryptLibraryResponse exposing (..)

import Data.Library as Library
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias EncryptLibraryResponse =
    { oldHash : String
    , newHash : String
    , library : Library.Library
    }


decoder : Decoder EncryptLibraryResponse
decoder =
    decode EncryptLibraryResponse
        |> required "oldHash" Decode.string
        |> required "newHash" Decode.string
        |> required "library" Library.decoder


decodeFromJson : Value -> Maybe EncryptLibraryResponse
decodeFromJson json =
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.andThen (Decode.decodeString decoder >> Result.toMaybe)
