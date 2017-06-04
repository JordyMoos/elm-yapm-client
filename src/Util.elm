module Util exposing ((=>), dictGetWithDefault)

import Dict exposing (Dict)


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


dictGetWithDefault : Dict comparable v -> v -> comparable -> v
dictGetWithDefault dict default key =
    Dict.get key dict
        |> Maybe.withDefault default
