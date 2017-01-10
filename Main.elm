module Main exposing (..)

import Basics exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http


apiEndPoint = "http://localhost:8001"


main : Program Never Model Msg
main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }


type alias Model =
  { masterKey : String
  , library : String
  }


init : (Model, Cmd Msg)
init =
  (Model "" "", Cmd.none)


type Msg
  = NoOp
  | DownloadLibrary
  | NewLibrary (Result Http.Error String)
  | SetMasterKey String


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

    DownloadLibrary ->
      (model, downloadLibrary)

    NewLibrary (Ok newLibrary) ->
      ({ model | library = newLibrary }, Cmd.none)

    NewLibrary (Err _) ->
      (model, Cmd.none)

    SetMasterKey newMasterKey ->
      ({ model | masterKey = newMasterKey }, Cmd.none)


downloadLibrary : Cmd Msg
downloadLibrary =
  Http.send NewLibrary (Http.getString apiEndPoint)


view : Model -> Html Msg
view model =
  div
    []
    [ viewUnAuthSection model ]


viewUnAuthSection : Model -> Html Msg
viewUnAuthSection model =
  section
    []
    [ div
       []
       [ h1 [] [ text "Online Password Manager" ]
       , viewLoginForm model
       , p [] [ text model.masterKey ]
       , p [] [ text model.library ]
       ]
    ]


viewLoginForm : Model -> Html Msg
viewLoginForm model =
  div
    []
    [ input [ placeholder "master key", onInput SetMasterKey ] []
    , button [ onClick DownloadLibrary ] [ text "Decrypt" ]
    ]
