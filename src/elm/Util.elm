module Util exposing ((=>), dictGetWithDefault, isValidPassword, focus, blur)

import Dict exposing (Dict)
import Dom
import Task


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


dictGetWithDefault : Dict comparable v -> v -> comparable -> v
dictGetWithDefault dict default key =
    Dict.get key dict
        |> Maybe.withDefault default


isValidPassword : Dict String String -> String -> String -> Bool
isValidPassword dict passwordKey repeatKey =
    let
        password =
            Dict.get passwordKey dict

        repeat =
            Dict.get repeatKey dict
    in
        Maybe.withDefault 0 (Maybe.map String.length password) >= 3 && password == repeat


focus : String -> msg -> Cmd msg
focus elementId onSucessMsg =
    Dom.focus elementId
        |> Task.attempt (\_ -> onSucessMsg)

blur : String -> msg -> Cmd msg
blur elementId onSucessMsg =
    Dom.blur elementId
        |> Task.attempt (\_ -> onSucessMsg)
