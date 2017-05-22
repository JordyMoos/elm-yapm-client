port module Ports exposing (..)

import Json.Encode exposing (Value)
import Data.Library as Library


port parseLibraryData : ParseLibraryDataContent -> Cmd msg


port encryptLibraryData : EncryptLibraryDataContent -> Cmd msg


port copyPasswordToClipboard : ElementId -> Cmd msg


port notification : (Value -> msg) -> Sub msg


port loginSuccess : (Value -> msg) -> Sub msg


port uploadLibrary : (Value -> msg) -> Sub msg
