module Data.Library exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required, optional)
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias Library =
    { hmac : String
    , library : String
    }


decoder : Decoder Library
decoder =
    decode Library
        |> required "hmac" Decode.string
        |> required "library" Decode.string


encode : Library -> Value
encode library =
    Encode.object
        [ "hmac" => Encode.string library.hmac
        , "library" => Encode.string library.library
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
