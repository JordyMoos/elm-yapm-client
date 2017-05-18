module Unauth exposing (..)

import Msg exposing (NoOp)


type alias Model =
    { error : Maybe String
    , masterKeyInput : String
    , isDownloading : Bool
    , libraryData : Maybe LibraryData
    }


type Msg
    = NoOp
    | DownloadLibrary
    | NewLibrary (Result Http.Error LibraryData)
    | SetMasterKeyInput String
    | SubmitAuthForm
    | SetError String
    | ClearError


init : Flags -> ( Model, Cmd Msg )
init flags =
    { error = Nothing
    , masterKeyInput = ""
    , isDownloading = False
    , libraryData = Nothing
    }
        ! [ focusMasterKeyInputCmd, downloadLibraryCmd flags.apiEndPoint ]


focusMasterKeyInputCmd : Cmd Msg
focusMasterKeyInputCmd =
    Task.attempt (\_ -> NoOp) <| Dom.focus "encryptionKey"


downloadLibraryCmd : String -> Cmd Msg
downloadLibraryCmd apiEndPoint =
    Http.send NewLibrary (Http.get apiEndPoint decodeLibraryData)


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ error SetError
        , passwords SetPasswords
        ]


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
