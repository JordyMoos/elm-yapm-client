module NewMasterKey.Msg exposing (..)


type Msg
  = NoOp
  | KeyInput String
  | RepeatInput String
  | Submit
  | SubmitConfirmation
  | Close
