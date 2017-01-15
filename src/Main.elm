port module Main exposing (main)

import Basics exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra exposing (isNothing)
import Dom
import Task
import Time
import Mouse
import Debug


main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


type alias Flags =
  { apiEndPoint : String
  , localStorageKey : String
  , maxIdleTime : Int
  }


type alias Model =
  { config : Flags
  , masterKeyInput : String
  , masterKey : Maybe MasterKey
  , isDownloading : Bool
  , libraryData : Maybe LibraryData
  , error : Maybe String
  , passwords : (List WrappedPassword)
  , isAuthenticated : Bool
  , modal : Maybe Modal
  , idleTime : Int
  , uid : Int
  , newMasterKeyForm : MasterKeyForm
  , filter : String
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
  { masterKey : Maybe MasterKey
  , libraryData : Maybe LibraryData
  }


type alias EncryptLibraryDataContent =
  { oldMasterKey : Maybe MasterKey
  , oldLibraryData : Maybe LibraryData
  , newMasterKey : Maybe MasterKey
  , passwords : List Password
  }


type alias UploadLibraryContent =
  { oldHash : String
  , newHash : String
  , libraryData : LibraryData
  }


type alias Password =
  { comment : String
  , password : String
  , title : String
  , url : String
  , username : String
  }


type alias WrappedPassword =
  { password : Password
  , id : Int
  , isVisible : Bool
  }


type alias MasterKeyForm =
  { masterKey : String
  , masterKeyRepeat : String
  }


type Modal
  = EditPassword
  | NewPassword
  | NewMasterKey
  | NewMasterKeyConfirmation
  | DeletePasswordConfirmation Int


type alias ElementId = String


type alias PasswordId = Int


type alias MasterKey = String


initModel : Flags -> Model
initModel flags =
  { config = flags
  , masterKeyInput = ""
  , masterKey = Nothing
  , isDownloading = False
  , libraryData = Nothing
  , error = Nothing
  , passwords = []
  , isAuthenticated = False
  , modal = Nothing
  , idleTime = 0
  , uid = 0
  , newMasterKeyForm = MasterKeyForm "" ""
  , filter = ""
  }


init : Flags -> (Model, Cmd Msg)
init flags =
  initModel flags ! []
    |> focusMasterKeyInput
    |> doDownloadLibrary


focusMasterKeyInput : (Model, Cmd Msg) -> (Model, Cmd Msg)
focusMasterKeyInput (model, cmd) =
  model !
    [ cmd
    , focusMasterKeyInputCmd
    ]


focusMasterKeyInputCmd : Cmd Msg
focusMasterKeyInputCmd =
  Task.attempt (\_ -> NoOp) <| Dom.focus "encryptionKey"


doDownloadLibrary : (Model, Cmd Msg) -> (Model, Cmd Msg)
doDownloadLibrary (model, cmd) =
  { model | isDownloading = True } !
    [ cmd
    , downloadLibraryCmd model.config.apiEndPoint
    ]


type Msg
  = NoOp
  | DownloadLibrary
  | UploadLibrary UploadLibraryContent
  | UploadLibraryResponse (Maybe LibraryData) (Maybe MasterKey) (Result Http.Error String)
  | NewLibrary (Result Http.Error LibraryData)
  | SetMasterKeyInput String
  | SubmitAuthForm
  | SetError String
  | ClearError
  | SetPasswords (List Password)
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
  | NewMasterKeyInput String
  | NewMasterKeyRepeatInput String
  | NewMasterKeySubmit
  | ConfirmNewMasterKey
  | UpdateFilter String


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      model ! []

    DownloadLibrary ->
      model ! [ downloadLibraryCmd model.config.apiEndPoint ]

    UploadLibrary uploadLibraryContent ->
      let
        _ = Debug.log "Hash Old" uploadLibraryContent.oldHash
        _ = Debug.log "Hash New" uploadLibraryContent.newHash
        _ = Debug.log "Library" uploadLibraryContent.libraryData.library
      in
        { model | libraryData = Just uploadLibraryContent.libraryData }
          ! [ uploadLibraryCmd model.config.apiEndPoint uploadLibraryContent model.libraryData model.masterKey ]

    UploadLibraryResponse _ _ (Ok message) ->
      let
        _ = Debug.log "Upload success" message
      in
        model ! []

    UploadLibraryResponse previousLibraryData previousMasterKey (Err errorValue) ->
      let
        _ = Debug.log "Response error" (toString errorValue)
      in
        { model
          | error = Just "Upload error"
          , libraryData = previousLibraryData
          , masterKey = previousMasterKey
        }
          ! []

    NewLibrary (Ok newLibraryData) ->
      let
        newModel = { model | libraryData = Just newLibraryData }
      in
        newModel ! [ decryptLibraryIfPossibleCmd newModel ]

    NewLibrary (Err _) ->
      { model | error = Just "Fetching library failed" } ! []

    SetMasterKeyInput masterKeyInput ->
      { model | masterKeyInput = masterKeyInput } ! []

    SubmitAuthForm ->
      let
        masterKey = Just model.masterKeyInput
        masterKeyInput = ""
        newModel = { model | masterKey = masterKey, masterKeyInput = masterKeyInput }
      in
        newModel ! [ decryptLibraryIfPossibleCmd newModel ]

    SetError error ->
      { model | error = Just error } ! []

    ClearError ->
      { model | error = Nothing } ! []

    SetPasswords passwords ->
      let
        firstId = model.uid
        lastId = model.uid + List.length passwords - 1
        ids = List.range firstId lastId

        wrappedPasswords = List.map2
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

    NewMasterKeyInput value ->
      let
        masterKeyForm = model.newMasterKeyForm
        newMasterKeyForm = { masterKeyForm | masterKey = value }
      in
        { model | newMasterKeyForm = newMasterKeyForm } ! []

    NewMasterKeyRepeatInput value ->
      let
        masterKeyForm = model.newMasterKeyForm
        newMasterKeyForm = { masterKeyForm | masterKeyRepeat = value }
      in
        { model | newMasterKeyForm = newMasterKeyForm } ! []

    NewMasterKeySubmit ->
      if not (isNewMasterKeyFormValid model.newMasterKeyForm) then
        { model | error = Just "Master key form is not valid" } ! []
      else
        { model | modal = Just NewMasterKeyConfirmation } ! []

    ConfirmNewMasterKey ->
      if not (isNewMasterKeyFormValid model.newMasterKeyForm) then
        { model | error = Just "Master key form is not valid" } ! []
      else
        { model
          | newMasterKeyForm = MasterKeyForm "" ""
          , masterKey = Just model.newMasterKeyForm.masterKey
          , modal = Nothing
        }
          ! [ createEncryptLibraryCmd model (Just model.newMasterKeyForm.masterKey) ]

    UpdateFilter newFilter ->
      { model | filter = newFilter, idleTime = 0 } ! []


port parseLibraryData : ParseLibraryDataContent -> Cmd msg

port error : (String -> msg) -> Sub msg

port passwords : (List Password -> msg) -> Sub msg

port encryptLibraryData : EncryptLibraryDataContent -> Cmd msg

port uploadLibrary : (UploadLibraryContent -> msg) -> Sub msg

port copyPasswordToClipboard : ElementId -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
  if model.isAuthenticated then
    Sub.batch
      [ error SetError
      , passwords SetPasswords
      , uploadLibrary UploadLibrary
      , Time.every Time.second IncrementIdleTime
      , Mouse.clicks ResetIdleTime
      , Mouse.moves ResetIdleTime
      , Mouse.downs ResetIdleTime
      ]
  else
    Sub.batch
      [ error SetError
      , passwords SetPasswords
      ]


logout : Model -> Model
logout model =
  { model
    | passwords = []
    , masterKey = Nothing
    , idleTime = 0
    , isAuthenticated = False
  }


downloadLibraryCmd : String -> Cmd Msg
downloadLibraryCmd apiEndPoint =
  Http.send NewLibrary (Http.get apiEndPoint decodeLibraryData)


-- decodeLibraryData : (a -> b -> value)
decodeLibraryData =
  Decode.map2 LibraryData (Decode.field "library" Decode.string) (Decode.field "hmac" Decode.string)


encodeLibraryData : LibraryData -> String
encodeLibraryData libraryData =
  Encode.object
    [ ( "hmac", Encode.string libraryData.hmac )
    , ( "library", Encode.string libraryData.library )
    ]
    |> Encode.encode 0


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
uploadLibraryBody {oldHash, newHash, libraryData} =
  let
    addNewHashIfChanged oldHash newHash =
      if oldHash == newHash then
        ""
      else
        "&newhash=" ++ newHash

    encodedLibrary = encodeLibraryData libraryData
      |> Http.encodeUri
    params = "pwhash=" ++ oldHash ++ "&newlib=" ++ encodedLibrary ++ (addNewHashIfChanged oldHash newHash)
  in
    Http.stringBody "application/x-www-form-urlencoded" params


decryptLibraryIfPossibleCmd : Model -> Cmd Msg
decryptLibraryIfPossibleCmd model =
  if areDecryptRequirementsMet model then
    parseLibraryData (ParseLibraryDataContent model.masterKey model.libraryData)
  else
    Cmd.none


areDecryptRequirementsMet : Model -> Bool
areDecryptRequirementsMet model =
  let
    unMetRequirements = [ isNothing model.masterKey, isNothing model.libraryData ]
      |> List.filter (\value -> value)
  in
    List.length unMetRequirements == 0


unwrapPasswords : List WrappedPassword -> List Password
unwrapPasswords wrappedPasswords =
  List.map (\wrapper -> wrapper.password) wrappedPasswords


createEncryptLibraryCmd : Model -> Maybe MasterKey -> Cmd Msg
createEncryptLibraryCmd model newMasterKey =
  EncryptLibraryDataContent
    model.masterKey
    model.libraryData
    (Maybe.withDefault model.masterKey (Just newMasterKey)) -- Ugly line could be better
    (unwrapPasswords model.passwords)
    |> encryptLibraryData


isNewMasterKeyFormValid : MasterKeyForm -> Bool
isNewMasterKeyFormValid form =
  if (String.length form.masterKey) < 3 then
    False
  else if form.masterKey /= form.masterKeyRepeat then
    False
  else
    True


view : Model -> Html Msg
view model =
  if model.isAuthenticated then
    viewManager model
  else
    viewUnAuthSection model


viewUnAuthSection : Model -> Html Msg
viewUnAuthSection model =
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


viewManager : Model -> Html Msg
viewManager model =
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
            [ text "Passwords" ] ]
    , div [ class "navbar" ]
        [ div [ class "navbar-form navbar-right", attribute "role" "form" ]
            [ div [ class "form-group" ]
                [ input [
                    id "filter"
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
viewPassword {password, id, isVisible} =
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
      viewNewMasterKeyModal model

    Just NewMasterKeyConfirmation ->
      viewNewMasterKeyConfirmationModal

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
        (Decode.at ["target", "id"] Decode.string)
  ]


viewModalContainer : List (Html Msg) -> Html Msg
viewModalContainer html =
  div 
    ( onSelfClickWithId "modal" ++ [ class "modal visible-modal" ] )
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


viewNewMasterKeyModal : Model -> Html Msg
viewNewMasterKeyModal model =
  viewModalContainer
    [ viewModalHeader "New Master Key"
    , viewNewMasterKeyForm model
    , div [ class "modal-footer" ]
        [ a [ class "btn btn-primary", onClick NewMasterKeySubmit ]
            [ i [ class "icon-attention" ] []
            , text "Save"
            ]
        ]
    ]


viewNewMasterKeyForm : Model -> Html Msg
viewNewMasterKeyForm model =
  Html.form [ class "modal-body form-horizontal" ]
    [ viewFormInput "key" "New Master Key" "password" model.newMasterKeyForm.masterKey (NewMasterKeyInput)
    , viewFormInput "keyRepeat" "Master Key Repeat" "password" model.newMasterKeyForm.masterKeyRepeat (NewMasterKeyRepeatInput)
    ]


viewNewMasterKeyConfirmationModal : Html Msg
viewNewMasterKeyConfirmationModal =
  viewModalContainer
    [ viewModalHeader "New Master Key Confirmation"
    , div [ class "modal-body" ]
      [ p []
        [ text "Are you sure you want to create a new master key?" ]
      ]
    , div [ class "modal-footer" ]
        [ a [ class "btn btn-default", onClick CloseModal ]
            [ text "No Cancel" ]
        , a [ class "btn btn-danger", onClick ConfirmNewMasterKey ]
            [ text "Yes Create" ]
        ]
    ]


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
