module PageState.Unauth exposing (..)

import Task
import Dom
import Http
import Json.Decode as Decode exposing (Value)
import Ports
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe.Extra exposing (isNothing)
import Data.Notification as Notification
import Data.Library as Library
import Data.LoginRequest as LoginRequest
import Data.User as User
import Data.Config exposing (Config)


type alias Model =
    { config : Config
    , notification : Maybe Notification.Notification
    , isDownloading : Bool
    , library : Maybe Library.Library
    , masterKeyInput : String
    , masterKey : Maybe String
    }


type Msg
    = NoOp
    | DownloadLibrary
    | NewLibrary (Result Http.Error Library.Library)
    | SetMasterKeyInput String
    | SubmitAuthForm
    | SetNotification Value
    | ClearNotification
    | SetUser (Maybe User.User)


type SupervisorCmd
    = None
    | Login User.User


init : Config -> ( Model, Cmd Msg )
init config =
    { config = config
    , notification = Nothing
    , isDownloading = False
    , library = Nothing
    , masterKeyInput = ""
    , masterKey = Nothing
    }
        ! [ focusMasterKeyInputCmd, downloadLibraryCmd config.apiEndPoint ]


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Ports.notification SetNotification
        , Sub.map SetUser loginSuccess
        ]


loginSuccess : Sub (Maybe User.User)
loginSuccess =
    Ports.loginSuccess (Decode.decodeValue User.decoder >> Result.toMaybe)


update : Msg -> Model -> ( Model, Cmd Msg, SupervisorCmd )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none, None )

        DownloadLibrary ->
            ( model, downloadLibraryCmd model.config.apiEndPoint, None )

        NewLibrary (Ok newLibrary) ->
            let
                newModel =
                    { model | library = Just newLibrary }
            in
                ( newModel, decryptLibraryIfPossibleCmd newModel, None )

        NewLibrary (Err _) ->
            let
                notification =
                    Notification.initError "Fetching library failed"
            in
                ( { model | notification = Just notification }, Cmd.none, None )

        SetMasterKeyInput masterKeyInput ->
            ( { model | masterKeyInput = masterKeyInput }, Cmd.none, None )

        SubmitAuthForm ->
            let
                masterKey =
                    Just model.masterKeyInput

                masterKeyInput =
                    ""

                newModel =
                    { model | masterKey = masterKey, masterKeyInput = masterKeyInput }
            in
                ( newModel, decryptLibraryIfPossibleCmd newModel, None )

        SetNotification json ->
            let
                notification =
                    Notification.decodeFromJson json
            in
                ( { model | notification = notification }, Cmd.none, None )

        ClearNotification ->
            ( { model | notification = Nothing }, Cmd.none, None )

        SetUser (Just user) ->
            ( model, Cmd.none, Login user )

        SetUser Nothing ->
            let
                notification =
                    Notification.initError "Could not parse the login success data"
            in
                ( { model | notification = Just notification }, Cmd.none, None )


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
    Http.send NewLibrary (Http.get apiEndPoint Library.decoder)


decryptLibraryIfPossibleCmd : Model -> Cmd Msg
decryptLibraryIfPossibleCmd model =
    case ( model.masterKey, model.library ) of
        ( Just masterKey, Just library ) ->
            Ports.login (LoginRequest.LoginRequest masterKey library)

        ( _, _ ) ->
            Cmd.none
