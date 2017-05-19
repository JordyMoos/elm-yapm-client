port module Ports exposing (..)


port parseLibraryData : parseLibraryDataContent -> Cmd msg


port error : (String -> msg) -> Sub msg


port passwords : (List password -> msg) -> Sub msg


port encryptLibraryData : encryptLibraryDataContent -> Cmd msg


port uploadLibrary : (uploadLibraryContent -> msg) -> Sub msg


port copyPasswordToClipboard : elementId -> Cmd msg
