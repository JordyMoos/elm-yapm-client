module PageState.Auth.NewMasterKey exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Dict exposing (Dict)
import Views.Modal exposing (..)
import Util


type alias Model =
    { state : State
    , fields : Fields
    }


type alias Fields =
    Dict String String


type State
    = NewForm
    | ConfirmationForm


type Msg
    = NoOp
    | FieldInput String String
    | Submit
    | SubmitConfirmation
    | Close


type SupervisorCmd
    = None
    | Quit
    | SetNotification String String
    | SaveNewMasterKey (Maybe String)


init : Model
init =
    Model NewForm initFields


initFields : Fields
initFields =
    Dict.fromList
        [ ( "masterKey", "" )
        , ( "masterKeyRepeat", "" )
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

        Submit ->
            if Util.isValidPassword model.fields "masterKey" "masterKeyRepeat" then
                ( { model | state = ConfirmationForm }, Cmd.none, None )
            else
                ( model, Cmd.none, SetNotification "error" "Master key form is not valid" )

        SubmitConfirmation ->
            ( model, Cmd.none, SaveNewMasterKey (Dict.get "masterKey" model.fields) )

        Close ->
            ( model, Cmd.none, Quit )


view : Model -> Html Msg
view model =
    case model.state of
        NewForm ->
            viewFormModal model

        ConfirmationForm ->
            viewConfirmationModal model


viewFormModal : Model -> Html Msg
viewFormModal model =
    viewModalContainer
        Close
        NoOp
        [ viewModalHeader Close "New Master Key"
        , viewNewForm model
        , div []
            [ button
                [ class "btn-primary"
                , onClick Submit
                ]
                [ i [ class "icon-attention" ] []
                , text "Save"
                ]
            ]
        ]


viewConfirmationModal : Model -> Html Msg
viewConfirmationModal model =
    viewModalContainer
        Close
        NoOp
        [ viewModalHeader Close "New Master Key Confirmation"
        , div []
            [ p []
                [ text "Are you sure you want to create a new master key?" ]
            ]
        , div []
            [ button [ class "btn-default", onClick Close ]
                [ text "Cancel" ]
            , button [ class "btn-danger", onClick SubmitConfirmation ]
                [ text "Change Master Key" ]
            ]
        ]


viewNewForm : Model -> Html Msg
viewNewForm model =
    Html.form []
        [ viewFormInput "masterKey" model.fields "New Master Key" "password" FieldInput
        , viewFormInput "masterKeyRepeat" model.fields "Master Key Repeat" "password" FieldInput
        ]
