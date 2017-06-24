module PageState.Auth.Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Time
import Mouse
import Http
import Dom
import Task
import Json.Decode as Decode exposing (Value)
import Data.Config exposing (Config)
import Data.Password as Password
import Data.Library as Library
import Data.Notification as Notification
import Data.EncryptLibraryRequest as EncryptLibraryRequest
import Data.EncryptLibrarySuccess as EncryptLibrarySuccess
import Data.User as User
import Ports
import PageState.Auth.NewMasterKey as NewMasterKey
import PageState.Auth.PasswordEditor as PasswordEditor
import PageState.Auth.DeletePassword as DeletePassword
import List.Extra
import Maybe.Extra
import Keyboard exposing (KeyCode)
import Char exposing (toCode, fromCode)


type alias Model =
    { config : Config
    , masterKey : String
    , library : Library.Library
    , passwords : List WrappedPassword
    , uid : Int
    , filter : String
    , idleTime : Int
    , notifications : List Notification.Notification
    , modal : Modal
    , keysPressed : KeysPressed
    }


type alias KeysPressed =
    { ctrl : Bool
    , e : Bool
    }


type alias WrappedPassword =
    { password : Password.Password
    , id : PasswordId
    , isVisible : Bool
    }


type alias ElementId =
    String


type alias PasswordId =
    Int


type Modal
    = NoModal
    | NewMasterKeyModal NewMasterKey.Model
    | PasswordEditorModal PasswordEditor.Model
    | DeletePasswordModal DeletePassword.Model


type Msg
    = NoOp
    | KeyDown KeyCode
    | KeyUp KeyCode
    | AddNotification Value
    | NotifyCopy
    | UploadLibrary (Maybe EncryptLibrarySuccess.EncryptLibrarySuccess)
    | UploadLibraryResponse Library.Library String (Result Http.Error String)
    | IncrementIdleTime Time.Time
    | ResetIdleTime Mouse.Position
    | EncryptLibrary
    | TogglePasswordVisibility Int
    | UpdateFilter String
    | Logout
    | OpenNewMasterKeyModal
    | NewMasterKeyMsg NewMasterKey.Msg
    | OpenNewPasswordModal
    | OpenEditPasswordModal PasswordId
    | PasswordEditorMsg PasswordEditor.Msg
    | OpenDeletePasswordModal PasswordId
    | DeletePasswordMsg DeletePassword.Msg


type SupervisorCmd
    = None
    | Quit


init : Config -> User.User -> ( Model, Cmd Msg )
init config { library, masterKey, passwords } =
    let
        lastId =
            List.length passwords - 1

        ids =
            List.range 0 lastId

        wrappedPasswords =
            List.map2
                (\password -> \id -> WrappedPassword password id False)
                passwords
                ids

        model =
            { config = config
            , masterKey = masterKey
            , library = library
            , passwords = wrappedPasswords
            , uid = lastId
            , filter = ""
            , idleTime = 0
            , notifications = []
            , modal = NoModal
            , keysPressed = KeysPressed False False
            }
    in
        model ! []


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Sub.map UploadLibrary libraryEncriptionSuccess
        , Time.every Time.second IncrementIdleTime
        , Mouse.clicks ResetIdleTime
        , Mouse.moves ResetIdleTime
        , Mouse.downs ResetIdleTime
        , Keyboard.downs KeyDown
        , Keyboard.ups KeyUp
        ]


libraryEncriptionSuccess : Sub (Maybe EncryptLibrarySuccess.EncryptLibrarySuccess)
libraryEncriptionSuccess =
    Ports.encryptLibrarySuccess (Decode.decodeValue EncryptLibrarySuccess.decoder >> Result.toMaybe)


update : Msg -> Model -> ( Model, Cmd Msg, SupervisorCmd )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none, None )

        KeyDown keyCode ->
            let
                keysPressed =
                    updatePressedKeyState model.keysPressed keyCode True

                cmd =
                    if keysPressed.e && keysPressed.ctrl then
                        focusFilter
                    else
                        Cmd.none
            in
                ( { model | keysPressed = keysPressed }, cmd, None )

        KeyUp keyCode ->
            let
                keysPressed =
                    updatePressedKeyState model.keysPressed keyCode False
            in
                ( { model | keysPressed = keysPressed }, Cmd.none, None )

        UploadLibrary (Just uploadData) ->
            ( { model | library = uploadData.library }
            , uploadLibraryCmd model.config.apiEndPoint uploadData model.library model.masterKey
            , None
            )

        UploadLibrary Nothing ->
            let
                notifications =
                    (Notification.initError "Failed to parse the encrypted library") :: model.notifications
            in
                ( { model | notifications = notifications }, Cmd.none, None )

        UploadLibraryResponse _ _ (Ok _) ->
            ( model, Cmd.none, None )

        UploadLibraryResponse previousLibrary previousMasterKey (Err errorValue) ->
            let
                _ =
                    Debug.log "Response error" (toString errorValue)
                notifications =
                    (Notification.initError "Upload error.") :: model.notifications
            in
                ( { model
                    | notifications = notifications
                    , library = previousLibrary
                    , masterKey = previousMasterKey
                  }
                , Cmd.none
                , None
                )

        IncrementIdleTime _ ->
            if model.idleTime + 1 > model.config.maxIdleTime then
                ( model, Cmd.none, Quit )
            else
                ( { model | idleTime = model.idleTime + 1 }, Cmd.none, None )

        ResetIdleTime _ ->
            ( { model | idleTime = 0 }, Cmd.none, None )

        EncryptLibrary ->
            ( model, createEncryptLibraryCmd model Nothing, None )

        TogglePasswordVisibility id ->
            let
                updatePassword password =
                    if password.id == id then
                        { password | isVisible = not password.isVisible }
                    else
                        password
            in
                ( { model | passwords = List.map updatePassword model.passwords }, Cmd.none, None )

        UpdateFilter newFilter ->
            ( { model | filter = newFilter, idleTime = 0 }, Cmd.none, None )

        AddNotification json ->
            let
                notifications =
                    (Maybe.Extra.maybeToList <| Notification.decodeFromJson json)
                        ++ model.notifications
            in
                ( { model | notifications = notifications }, Cmd.none, None )

        NotifyCopy ->
            let
                notifications =
                    (Notification.init "notice" "Password copied.") :: model.notifications
            in
                ( { model | notifications = notifications }, Cmd.none, None )

        Logout ->
            ( model, Cmd.none, Quit )

        OpenNewMasterKeyModal ->
            ( { model | modal = (NewMasterKeyModal NewMasterKey.init) }
            , Cmd.none
            , None
            )

        NewMasterKeyMsg subMsg ->
            case model.modal of
                NewMasterKeyModal modal ->
                    let
                        ( modalModel, modalCmd, supervisorCmd ) =
                            NewMasterKey.update subMsg modal

                        ( newModel, newCmd, notifications ) =
                            case supervisorCmd of
                                NewMasterKey.None ->
                                    ( NewMasterKeyModal modalModel, Cmd.map NewMasterKeyMsg modalCmd, [] )

                                NewMasterKey.Quit ->
                                    ( NoModal, Cmd.none, [] )

                                NewMasterKey.SetNotification level message ->
                                    ( NewMasterKeyModal modalModel, Cmd.map NewMasterKeyMsg modalCmd, [ Notification.init level message ] )

                                NewMasterKey.SaveNewMasterKey maybeNewMasterKey ->
                                    ( NoModal, createEncryptLibraryCmd model maybeNewMasterKey, [] )

                        newNotifications =
                            notifications ++ model.notifications
                    in
                        ( { model | modal = newModel, notifications = newNotifications }, newCmd, None )

                _ ->
                    ( model, Cmd.none, None )

        OpenNewPasswordModal ->
            ( { model | modal = (PasswordEditorModal PasswordEditor.initNew) }
            , Cmd.none
            , None
            )

        OpenEditPasswordModal passwordId ->
            let
                maybePassword =
                    List.Extra.find (\password -> password.id == passwordId) model.passwords

                resultModel =
                    case maybePassword of
                        Just password ->
                            { model | modal = (PasswordEditorModal <| PasswordEditor.initEdit passwordId password.password) }

                        Nothing ->
                            model
            in
                ( resultModel, Cmd.none, None )

        PasswordEditorMsg subMsg ->
            case model.modal of
                PasswordEditorModal modal ->
                    let
                        ( modalModel, modalCmd, supervisorCmd ) =
                            PasswordEditor.update subMsg modal

                        ( newModel, newCmd ) =
                            case supervisorCmd of
                                PasswordEditor.None ->
                                    ( { model | modal = PasswordEditorModal modalModel }
                                    , Cmd.map PasswordEditorMsg modalCmd
                                    )

                                PasswordEditor.Quit ->
                                    ( { model | modal = NoModal }
                                    , Cmd.none
                                    )

                                PasswordEditor.SetNotification level message ->
                                    ( { model
                                        | modal = PasswordEditorModal modalModel
                                        , notifications = (Notification.init level message) :: model.notifications
                                      }
                                    , Cmd.map PasswordEditorMsg modalCmd
                                    )

                                PasswordEditor.AddPassword password ->
                                    let
                                        nextUid =
                                            model.uid + 1

                                        wrappedPassword =
                                            WrappedPassword password nextUid False

                                        updatedModel =
                                            { model
                                                | modal = NoModal
                                                , uid = nextUid
                                                , passwords = (wrappedPassword :: model.passwords)
                                            }
                                    in
                                        ( updatedModel
                                        , createEncryptLibraryCmd updatedModel Nothing
                                        )

                                PasswordEditor.SavePassword passwordId password ->
                                    let
                                        updatedWrappedPassword =
                                            WrappedPassword password passwordId False

                                        wrappedPasswords =
                                            List.Extra.replaceIf
                                                (\x -> x.id == passwordId)
                                                updatedWrappedPassword
                                                model.passwords

                                        updatedModel =
                                            { model
                                                | modal = NoModal
                                                , passwords = wrappedPasswords
                                            }
                                    in
                                        ( updatedModel
                                        , createEncryptLibraryCmd updatedModel Nothing
                                        )
                    in
                        ( newModel, newCmd, None )

                _ ->
                    ( model, Cmd.none, None )

        OpenDeletePasswordModal id ->
            let
                maybePassword =
                    List.Extra.find (\password -> password.id == id) model.passwords

                resultModel =
                    case maybePassword of
                        Just password ->
                            { model | modal = (DeletePasswordModal <| DeletePassword.init id password.password) }

                        Nothing ->
                            model
            in
                ( resultModel, Cmd.none, None )

        DeletePasswordMsg subMsg ->
            case model.modal of
                DeletePasswordModal modal ->
                    let
                        ( modalModel, modalCmd, supervisorCmd ) =
                            DeletePassword.update subMsg modal

                        ( newModel, newCmd ) =
                            case supervisorCmd of
                                DeletePassword.None ->
                                    ( { model | modal = DeletePasswordModal modalModel }
                                    , Cmd.map DeletePasswordMsg modalCmd
                                    )

                                DeletePassword.Quit ->
                                    ( { model | modal = NoModal }
                                    , Cmd.none
                                    )

                                DeletePassword.DeletePassword id ->
                                    let
                                        wrappedPasswords =
                                            List.Extra.filterNot (\password -> password.id == id) model.passwords

                                        updatedModel =
                                            { model
                                                | modal = NoModal
                                                , passwords = wrappedPasswords
                                            }
                                    in
                                        ( updatedModel
                                        , createEncryptLibraryCmd updatedModel Nothing
                                        )
                    in
                        ( newModel, newCmd, None )

                _ ->
                    ( model, Cmd.none, None )


view : Model -> Html Msg
view model =
    section [ id "authorized" ]
        [ viewNavBar model
        , viewPasswordTable model
        , viewNotifications model.notifications
        , viewModal model.modal
        ]


viewModal : Modal -> Html Msg
viewModal modal =
    case modal of
        NoModal ->
            text ""

        NewMasterKeyModal subModel ->
            Html.map NewMasterKeyMsg (NewMasterKey.view subModel)

        PasswordEditorModal subModel ->
            Html.map PasswordEditorMsg (PasswordEditor.view subModel)

        DeletePasswordModal subModel ->
            Html.map DeletePasswordMsg (DeletePassword.view subModel)


viewNotifications : List Notification.Notification -> Html Msg
viewNotifications notifications =
    div [ id "notificationContainer" ]
        <| List.reverse
        <| List.map viewNotification notifications


viewNotification : Notification.Notification -> Html Msg
viewNotification notificationData =
    div [ class <| "notification " ++ notificationData.level ]
        [ text <|
            notificationData.level
                ++ ": "
                ++ notificationData.message
                ++ " "
        ]


viewNavBar : Model -> Html Msg
viewNavBar model =
    nav [ attribute "role" "navigation" ]
        [ h2 [] [ text "Passwords" ]
        , div [ attribute "role" "form" ]
            [ input
                [ id "filter"
                , placeholder "Filter... <CTRL+E>"
                , onInput UpdateFilter
                ]
                []
            , text " "
            , button [ class "newPassword btn", onClick OpenNewPasswordModal ]
                [ i [ class "icon-plus" ] []
                , text " New Password"
                ]
            , button [ class "newMasterKey btn", onClick OpenNewMasterKeyModal ]
                [ i [ class "icon-wrench" ] []
                , text " New Master Key"
                ]
            ]
        ]


viewPasswordTable : Model -> Html Msg
viewPasswordTable model =
    ul [ id "overview" ] (viewPasswords model.filter model.passwords)


passwordFilter : String -> WrappedPassword -> Bool
passwordFilter filter password =
    List.all (\subfilter -> String.contains subfilter <| String.toLower password.password.title) <| String.split " " filter


viewPasswords : String -> List WrappedPassword -> List (Html Msg)
viewPasswords filter passwords =
    List.map viewPassword <| List.filter (passwordFilter <| String.toLower filter) passwords


viewPassword : WrappedPassword -> Html Msg
viewPassword { password, id, isVisible } =
    let
        stringId =
            toString id
    in
        li [ Html.Attributes.id ("password-" ++ stringId) ]
            [ div [ class "password-details" ]
                [ a [ href password.url ] [ text password.title ]
                , viewObscuredField ("password-username-" ++ stringId) password.username isVisible
                , viewObscuredField ("password-password-" ++ stringId) password.password isVisible
                , div [ class "comment" ] [ text password.comment ]
                ]
            , div [ class "actions" ]
                [ a [ class "copyable copyPassword"
                    , attribute "data-clipboard-text" password.password
                    , onClick NotifyCopy ]
                    [ i [ class "icon-docs" ] [] ]
                , a [ class "toggleVisibility", onClick (TogglePasswordVisibility id) ]
                    [ i [ class "icon-eye" ] [] ]
                , a [ class "editPassword", onClick (OpenEditPasswordModal id) ]
                    [ i [ class "icon-edit" ] [] ]
                , a [ class "deletePassword", onClick (OpenDeletePasswordModal id) ]
                    [ i [ class "icon-trash" ] [] ]
                ]
            ]


viewObscuredField : String -> String -> Bool -> Html Msg
viewObscuredField fieldId message isVisible =
    span
        [ class ("copyable " ++ (getPasswordVisibility isVisible))
        , attribute "data-clipboard-text" message
        , id fieldId
        ]
        [ text message ]


getPasswordVisibility : Bool -> String
getPasswordVisibility isVisible =
    if isVisible then
        ""
    else
        "obscured"


uploadLibraryCmd : String -> EncryptLibrarySuccess.EncryptLibrarySuccess -> Library.Library -> String -> Cmd Msg
uploadLibraryCmd apiEndPoint uploadLibraryRequest oldLibrary oldMasterKey =
    Http.request
        { method = "POST"
        , headers = [ Http.header "Content-Type" "application/x-www-form-urlencoded" ]
        , url = apiEndPoint
        , body = (uploadLibraryBody uploadLibraryRequest)
        , expect = Http.expectString
        , timeout = Just (Time.second * 20)
        , withCredentials = False
        }
        |> Http.send (UploadLibraryResponse oldLibrary oldMasterKey)


uploadLibraryBody : EncryptLibrarySuccess.EncryptLibrarySuccess -> Http.Body
uploadLibraryBody { oldHash, newHash, library } =
    let
        addNewHashIfChanged oldHash newHash =
            if oldHash == newHash then
                ""
            else
                "&newhash=" ++ newHash

        encodedLibrary =
            Library.encodeAsString library
                |> Http.encodeUri

        params =
            "pwhash=" ++ oldHash ++ "&newlib=" ++ encodedLibrary ++ (addNewHashIfChanged oldHash newHash)
    in
        Http.stringBody "application/x-www-form-urlencoded" params


createEncryptLibraryCmd : Model -> Maybe String -> Cmd Msg
createEncryptLibraryCmd model newMasterKey =
    let
        unwrapPasswords : List WrappedPassword -> List Password.Password
        unwrapPasswords =
            List.map (\wrapper -> wrapper.password)
    in
        EncryptLibraryRequest.EncryptLibraryRequest
            model.masterKey
            model.library
            (Maybe.withDefault model.masterKey newMasterKey)
            (unwrapPasswords model.passwords)
            |> Ports.encryptLibrary


focusFilter : Cmd Msg
focusFilter =
    Dom.focus "filter"
        |> Task.attempt (\_ -> NoOp)


updatePressedKeyState : KeysPressed -> KeyCode -> Bool -> KeysPressed
updatePressedKeyState keysPressed keyCode replaceValue =
    case keyCode of
        69 ->
            { keysPressed | e = replaceValue }

        17 ->
            { keysPressed | ctrl = replaceValue }

        _ ->
            keysPressed
