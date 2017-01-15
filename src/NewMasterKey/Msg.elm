module NewMasterKey.Msg exposing (..)


type Msg
  = KeyInput String
  | RepeatInput String
  | Submit
  | SubmitConfirmation
  | Close
