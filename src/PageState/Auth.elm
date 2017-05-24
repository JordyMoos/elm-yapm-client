module PageState.Auth exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Flags exposing (Flags)
import Data.Password as Password
import Data.Library as Library
import Data.UploadLibraryRequest as UploadLibraryRequest
import Data.Notification as Notification
import Time
import Mouse
import Http
import Json.Decode as Decode exposing (Value)


type alias Model =
    { notification : Maybe Notification.Notification
    , flags : Flags
    , passwords : List WrappedPassword
    , filter : String
    , idleTime : Int
    , uid : Int
    , masterKey : String
    }


type alias WrappedPassword =
    { password : Password.Password
    , id : Int
    , isVisible : Bool
    }


type alias ElementId =
    String


type alias PasswordId =
    Int


type Msg
    = NoOp
    | SetNotification Value
    | ClearNotification
    | UploadLibrary UploadLibraryRequest.UploadLibraryRequest
    | UploadLibraryResponse (Maybe Library) (Maybe String) (Result Http.Error String)
    | IncrementIdleTime Time.Time
    | ResetIdleTime Mouse.Position
    | EncryptLibrary
    | TogglePasswordVisibility Int
    | CopyPasswordToClipboard ElementId
    | UpdateFilter String


init : Flags -> ( Model, Cmd Msg )
init flags passwords masterKey =
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
            { notification = Nothing
            , flags = flags
            , passwords = wrappedPasswords
            , filter = ""
            , idleTime = 0
            , uid = lastId
            , masterKey = masterKey
            }
    in
        model ! []


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ uploadLibrary UploadLibrary
        , Time.every Time.second IncrementIdleTime
        , Mouse.clicks ResetIdleTime
        , Mouse.moves ResetIdleTime
        , Mouse.downs ResetIdleTime
        ]


view : Model -> Html Msg
view model =
    section [ id "authorized" ]
        [ viewNavBar model
        , viewPasswordTable model
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


viewNavBar : Model -> Html Msg
viewNavBar model =
    nav [ class "navbar navbar-default navbar-fixed-top", attribute "role" "navigation" ]
        [ div [ class "navbar-header" ]
            [ a [ class "navbar-brand" ]
                [ text "Passwords" ]
            ]
        , div [ class "navbar" ]
            [ div [ class "navbar-form navbar-right", attribute "role" "form" ]
                [ div [ class "form-group" ]
                    [ input
                        [ id "filter"
                        , placeholder "Filter... <CTRL+E>"
                        , class "flter-control"
                        , onInput UpdateFilter
                        ]
                        []
                    ]
                , text " "
                , button [ class "save btn", onClick EncryptLibrary ]
                    [ i [ class "icon-floppy" ] []
                    , text " Save"
                    ]
                , button [ class "logout btn", onClick Logout ]
                    [ i [ class "icon-lock-open" ] []
                    , text " Logout"
                    ]
                ]
            ]
        ]


viewPasswordTable : Model -> Html Msg
viewPasswordTable model =
    div [ class "wide-container" ]
        [ table [ class "table table-striped", id "overview" ]
            [ thead []
                [ tr []
                    [ th [] [ text "Title" ]
                    , th [] [ text "Username" ]
                    , th [] [ text "Password" ]
                    , th [] [ text "Comment" ]
                    , th [] [ text "Actions" ]
                    ]
                ]
            , viewPasswords model.filter model.passwords
            ]
        ]


passwordFilter : String -> WrappedPassword -> Bool
passwordFilter filter password =
    List.all (\subfilter -> String.contains subfilter <| String.toLower password.password.title) <| String.split " " filter


viewPasswords : String -> List WrappedPassword -> Html Msg
viewPasswords filter passwords =
    tbody [] (List.map viewPassword <| List.filter (passwordFilter <| String.toLower filter) passwords)


viewPassword : WrappedPassword -> Html Msg
viewPassword { password, id, isVisible } =
    tr [ Html.Attributes.id ("password-" ++ (toString id)) ]
        [ td [] [ text password.title ]
        , td [] [ viewObscuredField ("password-username-" ++ (toString id)) password.username isVisible ]
        , td [] [ viewObscuredField ("password-password-" ++ (toString id)) password.password isVisible ]
        , td [] [ div [ class "comment" ] [ text password.comment ] ]
        , td []
            [ a [ class "copyPassword", onClick (CopyPasswordToClipboard ("password-password-" ++ (toString id))) ]
                [ i [ class "icon-docs" ] [] ]
            , a [ class "toggleVisibility", onClick (TogglePasswordVisibility id) ]
                [ i [ class "icon-eye" ] [] ]
            , a [ class "editPassword" ]
                [ i [ class "icon-edit" ] [] ]
            ]
        ]


viewObscuredField : String -> String -> Bool -> Html Msg
viewObscuredField fieldId message isVisible =
    div
        [ class (getPasswordVisibility isVisible)
        , id fieldId
        ]
        [ text message ]


getPasswordVisibility : Bool -> String
getPasswordVisibility isVisible =
    if isVisible then
        ""
    else
        "obscured"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        UploadLibrary uploadLibraryContent ->
            let
                _ =
                    Debug.log "Hash Old" uploadLibraryContent.oldHash

                _ =
                    Debug.log "Hash New" uploadLibraryContent.newHash

                _ =
                    Debug.log "Library" uploadLibraryContent.libraryData.library
            in
                { model | libraryData = Just uploadLibraryContent.libraryData }
                    ! [ uploadLibraryCmd model.config.apiEndPoint uploadLibraryContent model.libraryData model.masterKey ]

        UploadLibraryResponse _ _ (Ok message) ->
            let
                _ =
                    Debug.log "Upload success" message
            in
                model ! []

        UploadLibraryResponse previousLibraryData previousMasterKey (Err errorValue) ->
            let
                _ =
                    Debug.log "Response error" (toString errorValue)
            in
                { model
                    | error = Just "Upload error"
                    , libraryData = previousLibraryData
                    , masterKey = previousMasterKey
                }
                    ! []

        IncrementIdleTime _ ->
            if model.idleTime + 1 > model.config.maxIdleTime then
                logout model ! []
            else
                { model | idleTime = model.idleTime + 1 } ! []

        ResetIdleTime _ ->
            { model | idleTime = 0 } ! []

        EncryptLibrary ->
            model ! [ createEncryptLibraryCmd model Nothing ]

        TogglePasswordVisibility id ->
            let
                updatePassword password =
                    if password.id == id then
                        { password | isVisible = not password.isVisible }
                    else
                        password
            in
                { model | passwords = List.map updatePassword model.passwords } ! []

        CopyPasswordToClipboard elementId ->
            model ! [ copyPasswordToClipboard elementId ]

        UpdateFilter newFilter ->
            { model | filter = newFilter, idleTime = 0 } ! []


logout : Model -> Model
logout model =
    { model
        | passwords = []
        , masterKey = Nothing
        , idleTime = 0
        , isAuthenticated = False
    }


uploadLibraryCmd : String -> UploadLibraryContent -> Maybe LibraryData -> Maybe MasterKey -> Cmd Msg
uploadLibraryCmd apiEndPoint libraryContent oldLibraryData oldMasterKey =
    Http.request
        { method = "POST"
        , headers = [ Http.header "Content-Type" "application/x-www-form-urlencoded" ]
        , url = apiEndPoint
        , body = (uploadLibraryBody libraryContent)
        , expect = Http.expectString
        , timeout = Just (Time.second * 20)
        , withCredentials = False
        }
        |> Http.send (UploadLibraryResponse oldLibraryData oldMasterKey)


uploadLibraryBody : UploadLibraryContent -> Http.Body
uploadLibraryBody { oldHash, newHash, libraryData } =
    let
        addNewHashIfChanged oldHash newHash =
            if oldHash == newHash then
                ""
            else
                "&newhash=" ++ newHash

        encodedLibrary =
            encodeLibraryData libraryData
                |> Http.encodeUri

        params =
            "pwhash=" ++ oldHash ++ "&newlib=" ++ encodedLibrary ++ (addNewHashIfChanged oldHash newHash)
    in
        Http.stringBody "application/x-www-form-urlencoded" params


unwrapPasswords : List WrappedPassword -> List Password
unwrapPasswords wrappedPasswords =
    List.map (\wrapper -> wrapper.password) wrappedPasswords


createEncryptLibraryCmd : Model -> Maybe MasterKey -> Cmd Msg
createEncryptLibraryCmd model newMasterKey =
    EncryptLibraryDataContent
        model.masterKey
        model.libraryData
        (Maybe.withDefault model.masterKey (Just newMasterKey))
        -- Ugly line could be better
        (unwrapPasswords model.passwords)
        |> encryptLibraryData
