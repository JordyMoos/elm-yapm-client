module NewMasterKey.Update exposing (update)

import NewMasterKey.Msg exposing (Msg(..))
import Msg as MainMsg
import Cmd exposing
  ( isNewMasterKeyFormValid
  , createEncryptLibraryCmd
  , decryptLibraryIfPossibleCmd
  )
import Model exposing (..)


update : Msg -> Model -> (Model, Cmd MainMsg.Msg)
update msg model =
  case msg of
    NoOp ->
      model ! []

    Close ->
      { model | modal = Nothing } ! []

    KeyInput value ->
      let
        masterKeyForm = model.newMasterKeyForm
        newMasterKeyForm = { masterKeyForm | masterKey = value }
      in
        { model | newMasterKeyForm = newMasterKeyForm } ! []

    RepeatInput value ->
      let
        masterKeyForm = model.newMasterKeyForm
        newMasterKeyForm = { masterKeyForm | masterKeyRepeat = value }
      in
        { model | newMasterKeyForm = newMasterKeyForm } ! []

    Submit ->
      if not (isNewMasterKeyFormValid model.newMasterKeyForm) then
        { model | error = Just "Master key form is not valid" } ! []
      else
        { model | modal = Just NewMasterKeyConfirmation } ! []

    SubmitConfirmation ->
      if not (isNewMasterKeyFormValid model.newMasterKeyForm) then
        { model | error = Just "Master key form is not valid" } ! []
      else
        { model
          | newMasterKeyForm = MasterKeyForm "" ""
          , masterKey = Just model.newMasterKeyForm.masterKey
          , modal = Nothing
        }
          ! [ createEncryptLibraryCmd model (Just model.newMasterKeyForm.masterKey) ]
