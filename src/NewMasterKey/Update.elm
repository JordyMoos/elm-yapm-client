module NewMasterKey.Update exposing (update)

import Dict exposing (Dict)

import NewMasterKey.Msg exposing (Msg(..))
import Msg as MainMsg
import Cmd exposing
  ( createEncryptLibraryCmd
  , decryptLibraryIfPossibleCmd
  )
import Model exposing (Model, Modal(NewMasterKeyConfirmation))
import NewMasterKey.Model exposing (Fields, initModel)


update : Msg -> Model -> (Model, Cmd MainMsg.Msg)
update msg model =
  case msg of
    NoOp ->
      model ! []

    Close ->
      { model | modal = Nothing } ! []

    FieldInput name value ->
      let
        newFields = Dict.update name (Maybe.map <| fieldUpdate value ) model.newMasterKeyForm.fields
        masterKeyForm = model.newMasterKeyForm
        newMasterKeyForm = { masterKeyForm | fields = newFields }
      in
        { model | newMasterKeyForm = newMasterKeyForm } ! []

    Submit ->
      if not (isNewMasterKeyFormValid model.newMasterKeyForm.fields) then
        { model | error = Just "Master key form is not valid" } ! []
      else
        { model | modal = Just NewMasterKeyConfirmation } ! []

    SubmitConfirmation ->
      if not (isNewMasterKeyFormValid model.newMasterKeyForm.fields) then
        { model | error = Just "Master key form is not valid" } ! []
      else
        { model
          | newMasterKeyForm = initModel
          , masterKey = Dict.get "key" model.newMasterKeyForm.fields
          , modal = Nothing
        }
          ! [ createEncryptLibraryCmd model (Dict.get "key" model.newMasterKeyForm.fields) ]


fieldUpdate : String -> String -> String
fieldUpdate newValue field = newValue


isNewMasterKeyFormValid : Fields -> Bool
isNewMasterKeyFormValid fields =
  let
    key = Maybe.withDefault "" <| Dict.get "key" fields
    repeat = Maybe.withDefault "" <| Dict.get "repeat" fields
  in
    if (String.length key) < 3 then
      False
    else if key /= repeat then
      False
    else
      True
