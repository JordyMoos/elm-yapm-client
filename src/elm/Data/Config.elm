module Data.Config exposing (Config)


type alias Config =
    { apiEndPoint : String
    , localStorageKey : String
    , maxIdleTime : Int
    , randomPasswordSize : Int
    , masterKeyAllowEdit : Bool
    }
