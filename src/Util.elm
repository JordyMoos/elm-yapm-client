module Util exposing ((=>), dictGetWithDefault, isValidPassword)

import Dict exposing (Dict)


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
