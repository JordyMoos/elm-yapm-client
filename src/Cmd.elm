port module Cmd exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra exposing (isNothing)
import Http
import Dom
import Task
import Time

import Model exposing (..)
import Msg exposing (..)


port parseLibraryData : ParseLibraryDataContent -> Cmd msg

port error : (String -> msg) -> Sub msg

port passwords : (List Password -> msg) -> Sub msg

port encryptLibraryData : EncryptLibraryDataContent -> Cmd msg

port uploadLibrary : (UploadLibraryContent -> msg) -> Sub msg

port copyPasswordToClipboard : ElementId -> Cmd msg


logout : Model -> Model
logout model =
  { model
    | passwords = []
    , masterKey = Nothing
    , idleTime = 0
    , isAuthenticated = False
  }


focusMasterKeyInputCmd : Cmd Msg
focusMasterKeyInputCmd =
  Task.attempt (\_ -> NoOp) <| Dom.focus "encryptionKey"


downloadLibraryCmd : String -> Cmd Msg
downloadLibraryCmd apiEndPoint =
  Http.send NewLibrary (Http.get apiEndPoint decodeLibraryData)


-- decodeLibraryData : (a -> b -> value)
decodeLibraryData =
  Decode.map2 LibraryData (Decode.field "library" Decode.string) (Decode.field "hmac" Decode.string)


uploadLibraryCmd : String -> UploadLibraryContent -> Maybe LibraryData -> Maybe MasterKey -> Cmd Msg
uploadLibraryCmd apiEndPoint libraryContent oldLibraryData oldMasterKey =
  Http.request
    { method = "POST"
    , headers = [ Http.header "Content-Type" "application/x-www-form-urlencoded" ]
    , url = apiEndPoint
    , body = (uploadLibraryBody libraryContent)
    , expect = Http.expectString
    , timeout = Just (Time.second * 20)
    , withCredentials = False
    }
    |> Http.send (UploadLibraryResponse oldLibraryData oldMasterKey)


uploadLibraryBody : UploadLibraryContent -> Http.Body
uploadLibraryBody {oldHash, newHash, libraryData} =
  let
    addNewHashIfChanged oldHash newHash =
      if oldHash == newHash then
        ""
      else
        "&newhash=" ++ newHash

    encodedLibrary = encodeLibraryData libraryData
      |> Http.encodeUri
    params = "pwhash=" ++ oldHash ++ "&newlib=" ++ encodedLibrary ++ (addNewHashIfChanged oldHash newHash)
  in
    Http.stringBody "application/x-www-form-urlencoded" params


encodeLibraryData : LibraryData -> String
encodeLibraryData libraryData =
  Encode.object
    [ ( "hmac", Encode.string libraryData.hmac )
    , ( "library", Encode.string libraryData.library )
    ]
    |> Encode.encode 0


decryptLibraryIfPossibleCmd : Model -> Cmd Msg
decryptLibraryIfPossibleCmd model =
  if areDecryptRequirementsMet model then
    parseLibraryData (ParseLibraryDataContent model.masterKey model.libraryData)
  else
    Cmd.none


areDecryptRequirementsMet : Model -> Bool
areDecryptRequirementsMet model =
  let
    unMetRequirements = [ isNothing model.masterKey, isNothing model.libraryData ]
      |> List.filter (\value -> value)
  in
    List.length unMetRequirements == 0


unwrapPasswords : List WrappedPassword -> List Password
unwrapPasswords wrappedPasswords =
  List.map (\wrapper -> wrapper.password) wrappedPasswords


createEncryptLibraryCmd : Model -> Maybe MasterKey -> Cmd Msg
createEncryptLibraryCmd model newMasterKey =
  EncryptLibraryDataContent
    model.masterKey
    model.libraryData
    (Maybe.withDefault model.masterKey (Just newMasterKey)) -- Ugly line could be better
    (unwrapPasswords model.passwords)
    |> encryptLibraryData


isNewMasterKeyFormValid : MasterKeyForm -> Bool
isNewMasterKeyFormValid form =
  if (String.length form.masterKey) < 3 then
    False
  else if form.masterKey /= form.masterKeyRepeat then
    False
  else
    True
