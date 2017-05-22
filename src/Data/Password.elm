module Data.Password exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))
import List


type alias Password =
    { comment : String
    , password : String
    , title : String
    , url : String
    , username : String
    }


passwordDecoder : Decoder Password
passwordDecoder =
    decode Password
        |> required "comment" Decode.string
        |> required "password" Decode.string
        |> required "title" Decode.string
        |> required "url" Decode.string
        |> required "username" Decode.string


passwordsDecoder : Decoder (List Password)
passwordsDecoder =
    decode (Decode.list Password)
        |> required "passwords" (Decode.list passwordDecoder)


encode : Password -> Value
encode password =
    Encode.object
        [ "comment" => Encode.string password.comment
        , "password" => Encode.string password.password
        , "title" => Encode.string password.title
        , "url" => Encode.string password.url
        , "username" => Encode.string password.username
        ]


decodePasswordsFromJson : Value -> Maybe (List Password)
decodePasswordsFromJson json =
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.andThen (Decode.decodeString passwordsDecoder >> Result.toMaybe)
