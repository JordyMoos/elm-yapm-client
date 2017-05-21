module Unauth exposing (Model, Msg, init, subscriptions, update, view)

import Flags exposing (Flags)
import Task
import Dom
import Http
import Json.Decode as Decode
import Ports
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe.Extra exposing (isNothing)


type alias Model =
    { error : Maybe String
    , isDownloading : Bool
    , libraryData : Maybe LibraryData
    , masterKeyInput : String
    , masterKey : Maybe MasterKey
    }


type Msg
    = NoOp
    | DownloadLibrary
    | NewLibrary (Result Http.Error LibraryData)
    | SetMasterKeyInput String
    | SubmitAuthForm
    | SetError String
    | ClearError


type alias LibraryData =
    { library : String
    , hmac : String
    }


type alias ParseLibraryDataContent =
    { masterKey : Maybe MasterKey
    , libraryData : Maybe LibraryData
    }


type alias MasterKey =
    String


init : Flags -> ( Model, Cmd Msg )
init flags =
    { error = Nothing
    , isDownloading = False
    , libraryData = Nothing
    , masterKeyInput = ""
    , masterKey = Nothing
    }
        ! [ focusMasterKeyInputCmd, downloadLibraryCmd flags.apiEndPoint ]


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Ports.error SetError ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        DownloadLibrary ->
            model ! [ downloadLibraryCmd model.config.apiEndPoint ]

        NewLibrary (Ok newLibraryData) ->
            let
                newModel =
                    { model | libraryData = Just newLibraryData }
            in
                newModel ! [ decryptLibraryIfPossibleCmd newModel ]

        NewLibrary (Err _) ->
            { model | error = Just "Fetching library failed" } ! []

        SetMasterKeyInput masterKeyInput ->
            { model | masterKeyInput = masterKeyInput } ! []

        SubmitAuthForm ->
            let
                masterKey =
                    Just model.masterKeyInput

                masterKeyInput =
                    ""

                newModel =
                    { model | masterKey = masterKey, masterKeyInput = masterKeyInput }
            in
                newModel ! [ decryptLibraryIfPossibleCmd newModel ]

        SetError error ->
            { model | error = Just error } ! []

        ClearError ->
            { model | error = Nothing } ! []


view : ( Flags, Model ) -> Html Msg
view model =
    section
        [ id "unauthorized" ]
        [ div
            [ id "welcome" ]
            [ h1 [] [ text "Online Password Manager" ]
            , viewLoginForm model
            ]
        ]


viewLoginForm : Model -> Html Msg
viewLoginForm model =
    div
        []
        [ Html.form
            [ onSubmit SubmitAuthForm, class "well form-inline", id "decrypt" ]
            [ input
                [ placeholder "master key"
                , onInput SetMasterKeyInput
                , value model.masterKeyInput
                , class "form-control"
                , id "encryptionKey"
                , autocomplete False
                , attribute "type" "password"
                ]
                []
            , button
                [ class "btn" ]
                [ i [ class "icon-lock-open" ] []
                , text " Decrypt"
                ]
            ]
        , viewError model.error
        ]


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
            div [] [ text "[No Error]" ]


focusMasterKeyInputCmd : Cmd Msg
focusMasterKeyInputCmd =
    Dom.focus "encryptionKey"
        |> Task.attempt (\_ -> NoOp)


downloadLibraryCmd : String -> Cmd Msg
downloadLibraryCmd apiEndPoint =
    Http.send NewLibrary (Http.get apiEndPoint decodeLibraryData)


decodeLibraryData =
    Decode.map2 LibraryData (Decode.field "library" Decode.string) (Decode.field "hmac" Decode.string)



--
-- Refactor / Check scripts below
--


decryptLibraryIfPossibleCmd : Model -> Cmd Msg
decryptLibraryIfPossibleCmd model =
    if areDecryptRequirementsMet model then
        Ports.parseLibraryData (ParseLibraryDataContent model.masterKey model.libraryData)
    else
        Cmd.none


areDecryptRequirementsMet : Model -> Bool
areDecryptRequirementsMet model =
    let
        unMetRequirements =
            [ isNothing model.masterKey, isNothing model.libraryData ]
                |> List.filter (\value -> value)
    in
        List.length unMetRequirements == 0
