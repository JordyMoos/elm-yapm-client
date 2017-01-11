port module Main exposing (..)

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
  { masterKeyInput : String
  , masterKey : Maybe String
  , isDownloading : Bool
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
  { library : String
  , hmac : String
  }

initModel : Model
initModel =
  Model "" Nothing False Nothing Nothing


init : (Model, Cmd Msg)
init =
  doDownloadLibrary initModel


doDownloadLibrary : Model -> (Model, Cmd Msg)
doDownloadLibrary model =
  ({ model | isDownloading = True }, downloadLibraryCmd)


type Msg
  = DownloadLibrary
  | NewLibrary (Result Http.Error LibraryData)
  | SetMasterKeyInput String
  | SubmitAuthForm


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    DownloadLibrary ->
      (model, downloadLibraryCmd)

    NewLibrary (Ok newLibraryData) ->
      ({ model | libraryData = Just newLibraryData }, Cmd.none)

    NewLibrary (Err _) ->
      ({ model | error = Just "Fetching library failed" }, Cmd.none)

    SetMasterKeyInput masterKeyInput ->
      ({ model | masterKeyInput = masterKeyInput }, Cmd.none)

    SubmitAuthForm ->
      let
        masterKey = Just model.masterKeyInput
        masterKeyInput = ""
      in
        ({ model | masterKey = masterKey, masterKeyInput = masterKeyInput}, Cmd.none)


port parseLibraryData : LibraryData -> Cmd msg


downloadLibraryCmd : Cmd Msg
downloadLibraryCmd =
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
       , p [] [ text model.masterKeyInput ]
       , hr [] []
       , p [] [ text (Maybe.withDefault "" model.masterKey) ]
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
    [ input [ placeholder "master key", onInput SetMasterKeyInput, value model.masterKeyInput ] []
    , button [ onClick SubmitAuthForm ] [ text "Decrypt" ]
    ]


viewLibraryData : Maybe LibraryData -> Html Msg
viewLibraryData libraryData =
  case libraryData of
    Just data ->
      p [] [ text data.library ]

    Nothing ->
      text ""


viewError : Maybe String -> Html Msg
viewError error =
  text (Maybe.withDefault "" error)
