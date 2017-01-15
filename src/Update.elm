module Update exposing (update)

import Model exposing (..)
import Msg exposing (..)
import Cmd exposing (..)
import NewMasterKey.Update exposing (update)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      model ! []

    DownloadLibrary ->
      model ! [ downloadLibraryCmd model.config.apiEndPoint ]

    UploadLibrary uploadLibraryContent ->
      let
        _ = Debug.log "Hash Old" uploadLibraryContent.oldHash
        _ = Debug.log "Hash New" uploadLibraryContent.newHash
        _ = Debug.log "Library" uploadLibraryContent.libraryData.library
      in
        { model | libraryData = Just uploadLibraryContent.libraryData }
          ! [ uploadLibraryCmd model.config.apiEndPoint uploadLibraryContent model.libraryData model.masterKey ]

    UploadLibraryResponse _ _ (Ok message) ->
      let
        _ = Debug.log "Upload success" message
      in
        model ! []

    UploadLibraryResponse previousLibraryData previousMasterKey (Err errorValue) ->
      let
        _ = Debug.log "Response error" (toString errorValue)
      in
        { model
          | error = Just "Upload error"
          , libraryData = previousLibraryData
          , masterKey = previousMasterKey
        }
          ! []

    NewLibrary (Ok newLibraryData) ->
      let
        newModel = { model | libraryData = Just newLibraryData }
      in
        newModel ! [ decryptLibraryIfPossibleCmd newModel ]

    NewLibrary (Err _) ->
      { model | error = Just "Fetching library failed" } ! []

    SetMasterKeyInput masterKeyInput ->
      { model | masterKeyInput = masterKeyInput } ! []

    SubmitAuthForm ->
      let
        masterKey = Just model.masterKeyInput
        masterKeyInput = ""
        newModel = { model | masterKey = masterKey, masterKeyInput = masterKeyInput }
      in
        newModel ! [ decryptLibraryIfPossibleCmd newModel ]

    SetError error ->
      { model | error = Just error } ! []

    ClearError ->
      { model | error = Nothing } ! []

    SetPasswords passwords ->
      let
        firstId = model.uid
        lastId = model.uid + List.length passwords - 1
        ids = List.range firstId lastId

        wrappedPasswords = List.map2
          (\password -> \id -> WrappedPassword password id False)
          passwords
          ids
      in
        { model
          | passwords = wrappedPasswords
          , uid = lastId + 1
          , isAuthenticated = True
        }
          ! []

    Logout ->
      logout model ! [ focusMasterKeyInputCmd ]

    ShowNewPasswordModal ->
      { model | modal = Just NewPassword } ! []

    ShowNewMasterKeyModal ->
      { model | modal = Just NewMasterKey } ! []

    CloseModal ->
      { model | modal = Nothing } ! []

    IncrementIdleTime _ ->
      if model.idleTime + 1 > model.config.maxIdleTime then
        logout model ! [ focusMasterKeyInputCmd ]
      else
        { model | idleTime = model.idleTime + 1 } ! []

    ResetIdleTime _ ->
      { model | idleTime = 0 } ! []

    EncryptLibrary ->
      model ! [ createEncryptLibraryCmd model Nothing ]

    TogglePasswordVisibility id ->
      let
        updatePassword password =
          if password.id == id then
            { password | isVisible = not password.isVisible }
          else
            password
      in
        { model | passwords = List.map updatePassword model.passwords } ! []

    AskDeletePassword id ->
      { model | modal = Just (DeletePasswordConfirmation id) } ! []

    ConfirmDeletePassword id ->
      let
        newModel =
          { model
            | passwords = List.filter (\password -> password.id /= id) model.passwords
            , modal = Nothing
          }
      in
        newModel ! [ createEncryptLibraryCmd newModel Nothing ]

    CopyPasswordToClipboard elementId ->
      model ! [ copyPasswordToClipboard elementId ]

    MsgForNewMasterKey subMsg ->
      let
        ( newModel, cmd ) = NewMasterKey.Update.update subMsg model
      in
        ( newModel, Cmd.map MsgForNewMasterKey cmd )

    UpdateFilter newFilter ->
      { model | filter = newFilter, idleTime = 0 } ! []
