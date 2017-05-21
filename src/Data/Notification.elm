module Data.Notification exposing (Notification, initError, decoder, encode, decodeNotificationFromJson)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias Notification =
    { level : String
    , message : String
    }


initError : String -> Notification
initError message =
    { level = "error"
    , message = message
    }


decoder : Decoder Notification
decoder =
    decode Notification
        |> required "level" Decode.string
        |> required "message" Decode.string


encode : Notification -> Value
encode notification =
    Encode.object
        [ "level" => Encode.string notification.level
        , "message" => Encode.string notification.message
        ]


decodeNotificationFromJson : Value -> Maybe Notification
decodeNotificationFromJson json =
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.andThen (Decode.decodeString decoder >> Result.toMaybe)