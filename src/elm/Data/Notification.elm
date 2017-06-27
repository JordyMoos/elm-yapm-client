module Data.Notification exposing (..)

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
    init "error" message


initNotice : String -> Notification
initNotice message =
    init "notice" message


init : String -> String -> Notification
init level message =
    { level = level
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


decodeFromJson : Value -> Maybe Notification
decodeFromJson json =
    Decode.decodeValue decoder json |> Result.toMaybe
