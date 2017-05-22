port module Ports exposing (..)

import Json.Encode exposing (Value)
import Data.Library as Library
import Data.LoginRequest as LoginRequest
import Data.EncryptLibraryRequest as EncryptLibraryRequest


port login : LoginRequest.LoginRequest -> Cmd msg


port encryptLibrary : EncryptLibraryRequest.EncryptLibraryRequest -> Cmd msg


port copyPasswordToClipboard : Int -> Cmd msg


port notification : (Value -> msg) -> Sub msg


port loginSuccess : (Value -> msg) -> Sub msg


port encryptLibrarySuccess : (Value -> msg) -> Sub msg
