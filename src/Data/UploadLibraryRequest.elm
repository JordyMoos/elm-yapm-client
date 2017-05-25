module Data.UploadLibraryRequest exposing (..)

import Data.Library as Library
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias UploadLibraryRequest =
    { oldHash : String
    , newHash : String
    , library : Library.Library
    }


encode : UploadLibraryRequest -> Value
encode request =
    Encode.object
        [ "oldHash" => Encode.string request.oldHash
        , "newHash" => Encode.string request.newHash
        , "library" => Library.encode request.library
        ]


encodeAsString : UploadLibraryRequest -> String
encodeAsString request =
    encode request
        |> Encode.encode 0
