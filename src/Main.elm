port module Main exposing (main)

import Basics exposing (..)
import Html
import Time
import Mouse

import Model exposing (..)
import Msg exposing (..)
import Cmd exposing (..)
import Update exposing(..)
import View exposing (..)


main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


init : Flags -> (Model, Cmd Msg)
init flags =
  initModel flags ! []
    |> focusMasterKeyInput
    |> doDownloadLibrary


focusMasterKeyInput : (Model, Cmd Msg) -> (Model, Cmd Msg)
focusMasterKeyInput (model, cmd) =
  model !
    [ cmd
    , focusMasterKeyInputCmd
    ]


doDownloadLibrary : (Model, Cmd Msg) -> (Model, Cmd Msg)
doDownloadLibrary (model, cmd) =
  { model | isDownloading = True } !
    [ cmd
    , downloadLibraryCmd model.config.apiEndPoint
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
  if model.isAuthenticated then
    Sub.batch
      [ error SetError
      , passwords SetPasswords
      , uploadLibrary UploadLibrary
      , Time.every Time.second IncrementIdleTime
      , Mouse.clicks ResetIdleTime
      , Mouse.moves ResetIdleTime
      , Mouse.downs ResetIdleTime
      ]
  else
    Sub.batch
      [ error SetError
      , passwords SetPasswords
      ]
