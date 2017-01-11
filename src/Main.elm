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
    , subscriptions = subscriptions
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


type alias ParseLibraryDataContent =
  { masterKey : Maybe String
  , libraryData : Maybe LibraryData
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
  | SetError String
  | ClearError


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
        newModel = { model | masterKey = masterKey, masterKeyInput = masterKeyInput}
      in
        ( newModel, decryptLibraryIfPossibleCmd newModel )

    SetError error ->
      ({ model | error = Just error }, Cmd.none )

    ClearError ->
      ({ model | error = Nothing }, Cmd.none )


port parseLibraryData : ParseLibraryDataContent -> Cmd msg

port error : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [ error SetError ]


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


decryptLibraryIfPossibleCmd : Model -> Cmd Msg
decryptLibraryIfPossibleCmd model =
  if areDecryptRequirementsSet model then
    parseLibraryData (ParseLibraryDataContent model.masterKey model.libraryData)
  else
    Cmd.none


areDecryptRequirementsSet : Model -> Bool
areDecryptRequirementsSet model =
  let
    unMetRequirements = [ maybeIsNothing model.masterKey, maybeIsNothing model.libraryData ]
      |> List.filter (\value -> value)
  in
    List.length unMetRequirements == 0


maybeIsNothing : Maybe a -> Bool
maybeIsNothing maybe =
  case maybe of
    Nothing ->
      True
    Just _ ->
      False


maybeHasValue : Maybe a -> Bool
maybeHasValue maybe =
  not (maybeIsNothing maybe)


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
       , p [] [ text (Maybe.withDefault "[Nothing]" model.masterKey) ]
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
  case error of
    Just message ->
      div []
        [ text "Error: "
        , text message
        , text " "
        , button [ onClick ClearError ] [ text "[x]" ]
        ]

    Nothing ->
      text "[No Error]"
