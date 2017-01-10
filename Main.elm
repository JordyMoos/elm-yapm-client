module Main exposing (..)

import Basics exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode


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
  , libraryData : Maybe LibraryData
  , error : Maybe String
  }


type alias Library =
  { blob : String
  , libraryVersion : Int
  , apiVersion : Int
  , modified : Int
  }


type alias LibraryData =
  { libraryJson : String
  , hmac : String
  }

init : (Model, Cmd Msg)
init =
  (Model "" Nothing Nothing, Cmd.none)


type Msg
  = NoOp
  | DownloadLibrary
  | NewLibrary (Result Http.Error LibraryData)
  | SetMasterKey String


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

    DownloadLibrary ->
      ({ model | error = Nothing }, downloadLibrary)

    NewLibrary (Ok newLibraryData) ->
      ({ model | libraryData = Just newLibraryData }, Cmd.none)

    NewLibrary (Err _) ->
      ({ model | error = Just "Fetching library failed" }, Cmd.none)

    SetMasterKey newMasterKey ->
      ({ model | masterKey = newMasterKey }, Cmd.none)


downloadLibrary : Cmd Msg
downloadLibrary =
  Http.send NewLibrary (Http.get apiEndPoint decodeLibraryData)


-- decodeResponse : Decode.Decoder Library
-- decodeResponse =
--   Decode.at ["hmac"] Decode.string


decodeLibraryData =
  Decode.map2 LibraryData (Decode.field "library" Decode.string) (Decode.field "hmac" Decode.string)


decodeLibrary =
  Decode.map4 Library (Decode.field "blob" Decode.string) (Decode.field "library_version" Decode.int) (Decode.field "api_version" Decode.int) (Decode.field "modified" Decode.int)


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
       , hr [] []
       , viewLibraryData model.libraryData
       , hr [] []
       , viewError model.error
       ]
    ]


viewLoginForm : Model -> Html Msg
viewLoginForm model =
  div
    []
    [ input [ placeholder "master key", onInput SetMasterKey ] []
    , button [ onClick DownloadLibrary ] [ text "Decrypt" ]
    ]


viewLibraryData : Maybe LibraryData -> Html Msg
viewLibraryData libraryData =
  case libraryData of
    Just data ->
      p [] [ text data.libraryJson ]

    Nothing ->
      text ""


viewError : Maybe String -> Html Msg
viewError error =
  case error of
    Just message ->
      p [] [ text message ]

    Nothing ->
      text ""
