module Flags exposing (Flags)


type alias Flags =
    { apiEndPoint : String
    , localStorageKey : String
    , maxIdleTime : Int
    }
