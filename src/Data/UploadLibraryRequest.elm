module Data.UploadLibraryRequest exposing (..)

import Data.Library as Library
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias UploadLibraryRequest =
    { oldHash : String
    , newHash : String
    , library : Library.Library
    }


encode : UploadLibraryRequest -> Value
encode request =
    Encode.object
        [ "oldHash" => Encode.string request.oldHash
        , "newHash" => Encode.string request.newHash
        , "library" => Library.encode request.library
        ]


encodeAsString : UploadLibraryRequest -> String
encodeAsString request =
    encode request
        |> Encode.encode 0


decoder : Decoder UploadLibraryRequest
decoder =
    decode UploadLibraryRequest
        |> required "oldHash" Decode.string
        |> required "newHash" Decode.string
        |> required "library" Library.decoder


decodeFromJson : Value -> Maybe UploadLibraryRequest
decodeFromJson json =
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.andThen (Decode.decodeString decoder >> Result.toMaybe)
