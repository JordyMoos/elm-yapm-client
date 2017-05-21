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
import Data.Notification as Notification


type alias Model =
    { flags : Flags
    , notification : Maybe Notification.Notification
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
    | SetNotification Decode.Value
    | ClearNotification


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
    { flags = flags
    , notification = Nothing
    , isDownloading = False
    , libraryData = Nothing
    , masterKeyInput = ""
    , masterKey = Nothing
    }
        ! [ focusMasterKeyInputCmd, downloadLibraryCmd flags.apiEndPoint ]


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Ports.notification SetNotification ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        DownloadLibrary ->
            model ! [ downloadLibraryCmd model.flags.apiEndPoint ]

        NewLibrary (Ok newLibraryData) ->
            let
                newModel =
                    { model | libraryData = Just newLibraryData }
            in
                newModel ! [ decryptLibraryIfPossibleCmd newModel ]

        NewLibrary (Err _) ->
            let
                notification =
                    Notification.initError "Fetching library failed"
            in
                { model | notification = Just notification } ! []

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

        SetNotification json ->
            let
                notification =
                    Notification.decodeNotificationFromJson json
            in
                { model | notification = notification } ! []

        ClearNotification ->
            { model | notification = Nothing } ! []


view : Model -> Html Msg
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
        , viewNotification model.notification
        ]


viewNotification : Maybe Notification.Notification -> Html Msg
viewNotification notification =
    case notification of
        Just notificationData ->
            div []
                [ text <|
                    notificationData.level
                        ++ ": "
                        ++ notificationData.message
                        ++ " "
                , button [ onClick ClearNotification ] [ text "[x]" ]
                ]

        Nothing ->
            div [] [ text "[No Notification]" ]


focusMasterKeyInputCmd : Cmd Msg
focusMasterKeyInputCmd =
    Dom.focus "encryptionKey"
        |> Task.attempt (\_ -> NoOp)


downloadLibraryCmd : String -> Cmd Msg
downloadLibraryCmd apiEndPoint =
    Http.send NewLibrary (Http.get apiEndPoint decodeLibraryData)


decodeLibraryData =
    Decode.map2 LibraryData
        (Decode.field "library" Decode.string)
        (Decode.field "hmac" Decode.string)



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
