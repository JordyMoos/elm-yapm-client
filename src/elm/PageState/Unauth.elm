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
import Util


type alias Model =
    { config : Config
    , notifications : List Notification.Notification
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
    | AddNotification Value
    | ClearNotification Int
    | SetUser (Maybe User.User)


type SupervisorCmd
    = None
    | Login User.User


init : Config -> ( Model, Cmd Msg )
init config =
    { config = config
    , notifications = []
    , isDownloading = False
    , library = Nothing
    , masterKeyInput = ""
    , masterKey = Nothing
    }
        ! [ Util.focus "encryptionKey" NoOp, downloadLibraryCmd config.apiEndPoint ]


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Ports.notification AddNotification
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
                notifications =
                    Notification.initError "Fetching library failed." :: model.notifications
            in
                ( { model | notifications = notifications }, Cmd.none, None )

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

        AddNotification json ->
            let
                notifications =
                    (Maybe.Extra.maybeToList <| Notification.decodeFromJson json)
                        ++ model.notifications
            in
                ( { model | notifications = notifications }, Cmd.none, None )

        ClearNotification notificationId ->
            let
                notifications =
                    List.take (notificationId - 1) model.notifications
                        ++ List.drop notificationId model.notifications
            in
                ( { model | notifications = notifications }, Cmd.none, None )

        SetUser (Just user) ->
            ( model, Cmd.none, Login user )

        SetUser Nothing ->
            let
                notifications =
                    Notification.initError "Could not parse the login success data." :: model.notifications
            in
                ( { model | notifications = notifications }, Cmd.none, None )


view : Model -> Html Msg
view model =
    section
        [ id "unauthorized" ]
        [ div
            [ id "welcome" ]
            [ h1 [] [ text "Online Password Manager" ]
            , viewLoginForm model
            , viewNotifications model.notifications
            ]
        ]


viewLoginForm : Model -> Html Msg
viewLoginForm model =
    Html.form
        [ onSubmit SubmitAuthForm, id "decrypt" ]
        [ input
            [ placeholder "master key"
            , onInput SetMasterKeyInput
            , value model.masterKeyInput
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


viewNotifications : List Notification.Notification -> Html Msg
viewNotifications notifications =
    ol [ id "notificationList" ] <|
        List.map2 viewNotification notifications <|
            List.range 1 <|
                List.length notifications


viewNotification : Notification.Notification -> Int -> Html Msg
viewNotification notificationData notificationId =
    li []
        [ text <|
            notificationData.level
                ++ ": "
                ++ notificationData.message
                ++ " "
        , button
            [ onClick <| ClearNotification notificationId
            , class "close" ]
            []
        ]


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
