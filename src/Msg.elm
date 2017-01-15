module Msg exposing (..)

import Http
import Time
import Mouse

import Model exposing (..)
import NewMasterKey.Msg


type Msg
  = NoOp
  | DownloadLibrary
  | UploadLibrary UploadLibraryContent
  | UploadLibraryResponse (Maybe LibraryData) (Maybe MasterKey) (Result Http.Error String)
  | NewLibrary (Result Http.Error LibraryData)
  | SetMasterKeyInput String
  | SubmitAuthForm
  | SetError String
  | ClearError
  | SetPasswords (List Password)
  | Logout
  | ShowNewPasswordModal
  | ShowNewMasterKeyModal
  | CloseModal
  | IncrementIdleTime Time.Time
  | ResetIdleTime Mouse.Position
  | EncryptLibrary
  | TogglePasswordVisibility Int
  | AskDeletePassword Int
  | ConfirmDeletePassword PasswordId
  | CopyPasswordToClipboard ElementId
  | MsgForNewMasterKey NewMasterKey.Msg.Msg
  | UpdateFilter String
