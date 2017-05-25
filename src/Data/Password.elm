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


type alias Passwords =
    { passwords : List Password
    }


decoder : Decoder Password
decoder =
    decode Password
        |> required "comment" Decode.string
        |> required "password" Decode.string
        |> required "title" Decode.string
        |> required "url" Decode.string
        |> required "username" Decode.string


passwordsDecoder : Decoder Passwords
passwordsDecoder =
    decode Passwords
        |> required "passwords" (Decode.list decoder)


encode : Password -> Value
encode password =
    Encode.object
        [ "comment" => Encode.string password.comment
        , "password" => Encode.string password.password
        , "title" => Encode.string password.title
        , "url" => Encode.string password.url
        , "username" => Encode.string password.username
        ]


encodePasswords : List Password -> Value
encodePasswords passwords =
    let
        mapper password =
            Encode.object
                [ "comment" => Encode.string password.comment
                , "password" => Encode.string password.password
                , "title" => Encode.string password.title
                , "url" => Encode.string password.url
                , "username" => Encode.string password.username
                ]
    in
        List.map mapper passwords |> Encode.list


decodePasswordsFromJson : Value -> Maybe Passwords
decodePasswordsFromJson json =
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.andThen (Decode.decodeString passwordsDecoder >> Result.toMaybe)
