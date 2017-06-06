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
import Util
import Views.Modal exposing (..)


randomPasswordSize : Int
randomPasswordSize =
    16


type alias Model =
    { fields : Fields
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


type SupervisorCmd
    = None
    | Quit
    | SetNotification String String
    | SavePassword Password.Password


init : Model
init =
    Model initFields


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
            ( model, Random.generate RandomPassword randomPasswordGenerator, None )

        RandomPassword password ->
            let
                fields =
                    Dict.update "password" (Maybe.map (\x -> password)) model.fields

                newFields =
                    Dict.update "passwordRepeat" (Maybe.map (\x -> password)) fields
            in
                ( { model | fields = newFields }, Cmd.none, None )

        Submit ->
            if Util.isValidPassword model.fields "password" "passwordRepeat" then
                ( model, Cmd.none, SavePassword <| Password.fromDict model.fields )
            else
                ( model, Cmd.none, SetNotification "error" "Password form is not valid" )

        Close ->
            ( model, Cmd.none, Quit )


view : Model -> Html Msg
view model =
    div []
        [ viewModalContainer
            Close
            NoOp
            [ viewModalHeader Close "New Password"
            , viewForm model
            , div [ class "modal-footer" ]
                [ a
                    [ class "btn btn-default"
                    , onClick GetRandomPassword
                    ]
                    [ i [ class "icon-shuffle" ] []
                    , text "Random Password"
                    ]
                , a
                    [ class "btn btn-primary"
                    , onClick Submit
                    ]
                    [ i [ class "icon-attention" ] []
                    , text "Save"
                    ]
                ]
            ]
        ]


viewForm : Model -> Html Msg
viewForm model =
    Html.form [ class "modal-body form-horizontal" ]
        [ viewFormInput "title" model.fields "Title" "text" FieldInput
        , viewFormInput "url" model.fields "URL" "text" FieldInput
        , viewFormInput "username" model.fields "Username" "text" FieldInput
        , viewFormInput "password" model.fields "Password" "password" FieldInput
        , viewFormInput "passwordRepeat" model.fields "Password Repeat" "password" FieldInput
        , viewFormInput "comment" model.fields "Comment" "text" FieldInput
        ]


randomPasswordGenerator : Random.Generator String
randomPasswordGenerator =
    Random.Extra.choices
        [ Random.Char.upperCaseLatin
        , Random.Char.lowerCaseLatin
        , Random.Char.char 48 57
          -- Numbers
        , Random.Char.char 58 64
          -- Some special chars
        ]
        |> Random.String.string randomPasswordSize
