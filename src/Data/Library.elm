module Data.Library exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias Library =
    { library : String
    , hmac : String
    }


decoder : Decoder Library
decoder =
    decode Library
        |> required "library" Decode.string
        |> required "hmac" Decode.string


encode : Library -> Value
encode library =
    Encode.object
        [ "library" => Encode.string library.library
        , "hmac" => Encode.string library.hmac
        ]


encodeAsString : Library -> String
encodeAsString library =
    encode library
        |> Encode.encode 0


decodeFromJson : Value -> Maybe Library
decodeFromJson json =
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.andThen (Decode.decodeString decoder >> Result.toMaybe)
