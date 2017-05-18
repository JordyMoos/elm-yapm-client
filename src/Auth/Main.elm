module Auth exposing (..)

import Msg exposing (Msg(NoOp))


type alias Model =
    { passwords : List WrappedPassword
    , modal : Maybe Modal
    , filter : String
    , idleTime : Int
    , uid : Int
    , masterKey : MasterKey
    , newMasterKeyForm : NewMasterKey.Model.Model
    }


type Msg
    = NoOp
    | UploadLibrary UploadLibraryContent
    | UploadLibraryResponse (Maybe LibraryData) (Maybe MasterKey) (Result Http.Error String)
    | SetMasterKeyInput String
    | SubmitAuthForm
    | SetError String
    | ClearError
    | Logout
    | ShowNewPasswordModal
    | ShowNewMasterKeyModal
    | CloseModal
    | IncrementIdleTime Time.Time
    | ResetIdleTime Mouse.Position
    | EncryptLibrary
    | TogglePasswordVisibility Int
    | AskDeletePassword Int
    | ConfirmDeletePassword PasswordId
    | CopyPasswordToClipboard ElementId
    | MsgForNewMasterKey NewMasterKey.Msg.Msg
    | UpdateFilter String


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ error SetError
        , passwords SetPasswords
        , uploadLibrary UploadLibrary
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
        , viewModal model
        , viewError model.error
        ]


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
                , button [ class "newPassword btn", onClick ShowNewPasswordModal ]
                    [ i [ class "icon-plus" ] []
                    , text " New Password"
                    ]
                , button [ class "newMasterKey btn", onClick ShowNewMasterKeyModal ]
                    [ i [ class "icon-wrench" ] []
                    , text " Change Master Key"
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
            , a [ class "deletePassword", onClick (AskDeletePassword id) ]
                [ i [ class "icon-trash" ] [] ]
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


viewModal : Model -> Html Msg
viewModal model =
    case model.modal of
        Just EditPassword ->
            text "Show exit password"

        Just NewPassword ->
            viewNewPasswordModal model

        Just NewMasterKey ->
            NewMasterKey.View.viewModal model

        Just NewMasterKeyConfirmation ->
            NewMasterKey.View.viewConfirmationModal model

        Just (DeletePasswordConfirmation id) ->
            List.filter (\password -> password.id == id) model.passwords
                |> List.head
                |> viewDeletePasswordConfirmation

        Nothing ->
            text ""


onSelfClickWithId : String -> List (Attribute Msg)
onSelfClickWithId elementId =
    [ id elementId
    , on "click" <|
        Decode.map
            (\msg ->
                if msg == elementId then
                    CloseModal
                else
                    NoOp
            )
            (Decode.at [ "target", "id" ] Decode.string)
    ]


viewModalContainer : List (Html Msg) -> Html Msg
viewModalContainer html =
    div
        (onSelfClickWithId "modal" ++ [ class "modal visible-modal" ])
        [ div [ class "modal-dialog" ]
            [ div [ class "modal-content" ]
                html
            ]
        ]


viewModalHeader : String -> Html Msg
viewModalHeader title =
    div [ class "modal-header" ]
        [ button
            [ class "close"
            , onClick CloseModal
            , attribute "aria-hidden" "true"
            ]
            [ text "x" ]
        , h4 [ class "modal-title", id "modalHeader" ]
            [ text title ]
        ]


viewDeletePasswordConfirmation : Maybe WrappedPassword -> Html Msg
viewDeletePasswordConfirmation password =
    case password of
        Just password ->
            viewModalContainer
                [ viewModalHeader "Delete Password"
                , viewDeletePasswordContent password
                , div [ class "modal-footer" ]
                    [ a [ class "btn btn-default", onClick CloseModal ]
                        [ text "No Cancel" ]
                    , a [ class "btn btn-danger", onClick (ConfirmDeletePassword password.id) ]
                        [ text "Yes Delete" ]
                    ]
                ]

        Nothing ->
            text ""


viewDeletePasswordContent : WrappedPassword -> Html Msg
viewDeletePasswordContent password =
    div [ class "modal-body" ]
        [ p []
            [ text "Are you sure you want to delete this password?" ]
        ]


viewNewPasswordModal : Model -> Html Msg
viewNewPasswordModal model =
    viewModalContainer
        [ viewModalHeader "New Password"
        , viewNewPasswordForm model
        , div [ class "modal-footer" ]
            [ a [ class "btn btn-default" ]
                [ i [ class "icon-shuffle" ] []
                , text "Random Password"
                ]
            , a [ class "btn btn-primary" ]
                [ i [ class "icon-floppy" ] []
                , text "Save"
                ]
            ]
        ]


viewNewPasswordForm : Model -> Html Msg
viewNewPasswordForm model =
    Html.form [ class "modal-body form-horizontal" ]
        --
        -- Off for now because it is just visual an no longer compatible with the viewFormInput function
        --
        -- [ viewFormInput "title" "Title" "text"
        -- , viewFormInput "URL" "URL" "text"
        -- , viewFormInput "username" "Username" "text"
        -- , viewFormInput "pass" "Password" "password"
        -- , viewFormInput "passRepeat" "Password Repeat" "password"
        -- , viewFormTextarea "comment" "Comment"
        -- ]
        []


viewFormInput : String -> String -> String -> String -> (String -> Msg) -> Html Msg
viewFormInput inputId title inputType inputValue onInputAction =
    div
        [ class "form-group" ]
        [ label
            [ class "col-sm-4 control-label", for inputId ]
            [ text title ]
        , div
            [ class "col-sm-8" ]
            [ input
                [ attribute "type" inputType
                , value inputValue
                , onInput onInputAction
                , class "form-control"
                , id inputId
                ]
                []
            ]
        ]


viewFormTextarea : String -> String -> Html Msg
viewFormTextarea inputId title =
    div [ class "form-group" ]
        [ label [ class "col-sm-4 control-label", for inputId ]
            [ text title ]
        , div [ class "col-sm-8" ]
            [ textarea [ class "form-control", id inputId ] [] ]
        ]


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

        SetPasswords passwords ->
            let
                firstId =
                    model.uid

                lastId =
                    model.uid + List.length passwords - 1

                ids =
                    List.range firstId lastId

                wrappedPasswords =
                    List.map2
                        (\password -> \id -> WrappedPassword password id False)
                        passwords
                        ids
            in
                { model
                    | passwords = wrappedPasswords
                    , uid = lastId + 1
                    , isAuthenticated = True
                }
                    ! []

        Logout ->
            logout model ! [ focusMasterKeyInputCmd ]

        ShowNewPasswordModal ->
            { model | modal = Just NewPassword } ! []

        ShowNewMasterKeyModal ->
            { model | modal = Just NewMasterKey } ! []

        CloseModal ->
            { model | modal = Nothing } ! []

        IncrementIdleTime _ ->
            if model.idleTime + 1 > model.config.maxIdleTime then
                logout model ! [ focusMasterKeyInputCmd ]
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

        AskDeletePassword id ->
            { model | modal = Just (DeletePasswordConfirmation id) } ! []

        ConfirmDeletePassword id ->
            let
                newModel =
                    { model
                        | passwords = List.filter (\password -> password.id /= id) model.passwords
                        , modal = Nothing
                    }
            in
                newModel ! [ createEncryptLibraryCmd newModel Nothing ]

        CopyPasswordToClipboard elementId ->
            model ! [ copyPasswordToClipboard elementId ]

        MsgForNewMasterKey subMsg ->
            NewMasterKey.Update.update subMsg model

        UpdateFilter newFilter ->
            { model | filter = newFilter, idleTime = 0 } ! []
