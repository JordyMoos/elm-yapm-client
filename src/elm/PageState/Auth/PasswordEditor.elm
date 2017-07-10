module PageState.Auth.PasswordEditor exposing (..)

import Data.Password as Password
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Random
import Random.Char
import Random.String
import Random.Extra
import Maybe.Extra
import Util
import Views.Modal exposing (..)
import String.Extra exposing (toSentenceCase)


type alias Model =
    { fields : Fields
    , passwordId : Maybe Int
    , randomPasswordSize : Int
    }


type alias Fields =
    Dict String String


type Msg
    = NoOp
    | FieldInput String String
    | Submit
    | Close
    | GetRandomPassword
    | RandomPassword String
    | ContentCopied String


type SupervisorCmd
    = None
    | Quit
    | SetNotification String String
    | SavePassword Int Password.Password
    | AddPassword Password.Password


initNew : Int -> ( Model, Cmd Msg )
initNew passwordSize =
    ( Model initFields Nothing passwordSize
    , Cmd.batch [ Util.focus "title" NoOp, randomPasswordGenerator passwordSize ]
    )


initEdit : Int -> Password.Password -> Int -> ( Model, Cmd Msg )
initEdit passwordId password randomPasswordSize =
    let
        fields =
            Dict.fromList
                [ ( "title", password.title )
                , ( "url", password.url )
                , ( "username", password.username )
                , ( "password", password.password )
                , ( "passwordRepeat", password.password )
                , ( "comment", password.comment )
                ]
    in
        ( Model fields (Just passwordId) randomPasswordSize, Util.focus "title" NoOp )


initFields : Fields
initFields =
    Dict.fromList
        [ ( "title", "" )
        , ( "url", "" )
        , ( "username", "" )
        , ( "password", "" )
        , ( "passwordRepeat", "" )
        , ( "comment", "" )
        ]


update : Msg -> Model -> ( Model, Cmd Msg, SupervisorCmd )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none, None )

        FieldInput name value ->
            let
                newFields =
                    Dict.update name (Maybe.map (\x -> value)) model.fields
            in
                ( { model | fields = newFields }, Cmd.none, None )

        GetRandomPassword ->
            ( model, randomPasswordGenerator model.randomPasswordSize, None )

        RandomPassword password ->
            let
                fields =
                    Dict.update "password" (Maybe.map (\x -> password)) model.fields

                newFields =
                    Dict.update "passwordRepeat" (Maybe.map (\x -> password)) fields
            in
                ( { model | fields = newFields }, Cmd.none, None )

        ContentCopied category ->
            let
                message =
                    category
                        ++ " copied."
                        |> toSentenceCase
            in
                ( model, Cmd.none, SetNotification "notice" message )

        Submit ->
            if Util.isValidPassword model.fields "password" "passwordRepeat" then
                case model.passwordId of
                    Just passwordId ->
                        ( model, Cmd.none, SavePassword passwordId (Password.fromDict model.fields) )

                    Nothing ->
                        ( model, Cmd.none, AddPassword (Password.fromDict model.fields) )
            else
                ( model, Cmd.none, SetNotification "error" "Password form is not valid" )

        Close ->
            ( model, Cmd.none, Quit )


view : Model -> Html Msg
view model =
    let
        title =
            if Maybe.Extra.isJust model.passwordId then
                "Edit Password"
            else
                "New Password"
    in
        viewModalContainer
            Close
            NoOp
            [ viewModalHeader Close title
            , viewForm model
            , div []
                [ button
                    [ onClick GetRandomPassword ]
                    [ i [ class "icon-shuffle" ] []
                    , text "Random Password"
                    ]
                , button
                    [ onClick Submit ]
                    [ i [ class "icon-floppy" ] []
                    , text "Save"
                    ]
                ]
            ]


viewForm : Model -> Html Msg
viewForm model =
    Html.form []
        <| viewFormInput "title" model.fields "Title" "text" FieldInput
            ++ viewFormInput "url" model.fields "URL" "text" FieldInput
            ++ viewFormInput "username" model.fields "Username" "text" FieldInput
            ++ viewCopyPasswordFormInput (ContentCopied "password") "password" model.fields "Password" "password" FieldInput
            ++ viewFormInput "passwordRepeat" model.fields "Password Repeat" "password" FieldInput
            ++ viewFormInput "comment" model.fields "Comment" "text" FieldInput


randomPasswordGenerator : Int -> Cmd Msg
randomPasswordGenerator randomPasswordSize =
    Random.Extra.choices
        [ Random.Char.upperCaseLatin
        , Random.Char.lowerCaseLatin
        , Random.Char.char 48 57
          -- Numbers
        , Random.Char.char 58 64
          -- Some special chars
        ]
        |> Random.String.string randomPasswordSize
        |> Random.generate RandomPassword
