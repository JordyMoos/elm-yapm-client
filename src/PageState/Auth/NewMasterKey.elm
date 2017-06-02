module PageState.Auth.NewMasterKey exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Dict exposing (Dict)
import Views.Modal exposing (..)


type alias Model =
    { state : State
    , fields : Fields
    }


type alias Fields =
    Dict String String


type State
    = NewMasterKeyForm
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
    Model NewMasterKeyForm initFields


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
                    Dict.update name (Maybe.map <| fieldUpdate value) model.fields
            in
                ( { model | fields = newFields }, Cmd.none, None )

        Submit ->
            if not (isNewMasterKeyFormValid model.fields) then
                ( model, Cmd.none, SetNotification "error" "Master key form is not valid" )
            else
                ( { model | state = ConfirmationForm }, Cmd.none, None )

        SubmitConfirmation ->
            if not (isNewMasterKeyFormValid model.fields) then
                ( model, Cmd.none, SetNotification "error" "Master key form is not valid" )
            else
                ( model, Cmd.none, SaveNewMasterKey (Dict.get "masterKey" model.fields) )

        Close ->
            ( model, Cmd.none, Quit )


fieldUpdate : String -> String -> String
fieldUpdate newValue field =
    newValue


view : Model -> Html Msg
view model =
    case model.state of
        NewMasterKeyForm ->
            viewFormModal model

        ConfirmationForm ->
            viewConfirmationModal model


viewFormModal : Model -> Html Msg
viewFormModal model =
    div []
        [ viewModalContainer
            Close
            NoOp
            [ viewModalHeader Close "New Master Key"
            , viewNewMasterKeyForm model
            , div [ class "modal-footer" ]
                [ a
                    [ class "btn btn-primary"
                    , onClick Submit
                    ]
                    [ i [ class "icon-attention" ] []
                    , text "Save"
                    ]
                ]
            ]
        ]


viewConfirmationModal : Model -> Html Msg
viewConfirmationModal model =
    div []
        [ viewModalContainer
            Close
            NoOp
            [ viewModalHeader Close "New Master Key Confirmation"
            , div [ class "modal-body" ]
                [ p []
                    [ text "Are you sure you want to create a new master key?" ]
                ]
            , div [ class "modal-footer" ]
                [ a [ class "btn btn-default", onClick Close ]
                    [ text "No Cancel" ]
                , a [ class "btn btn-danger", onClick SubmitConfirmation ]
                    [ text "Yes Create" ]
                ]
            ]
        ]


viewNewMasterKeyForm : Model -> Html Msg
viewNewMasterKeyForm model =
    Html.form [ class "modal-body form-horizontal" ]
        [ viewFormInput "masterKey" model.fields "New Master Key" "password"
        , viewFormInput "masterKeyRepeat" model.fields "Master Key Repeat" "password"
        ]


viewFormInput : String -> Dict String String -> String -> String -> Html Msg
viewFormInput dictName fields title inputType =
    let
        maybeFieldValue =
            Dict.get dictName fields
    in
        case maybeFieldValue of
            Just fieldValue ->
                div
                    [ class "form-group" ]
                    [ label
                        [ class "col-sm-4 control-label", for dictName ]
                        [ text title ]
                    , div
                        [ class "col-sm-8" ]
                        [ input
                            [ attribute "type" inputType
                            , value fieldValue
                            , onInput (FieldInput dictName)
                            , class "form-control"
                            , id dictName
                            ]
                            []
                        ]
                    ]

            Nothing ->
                text ""


isNewMasterKeyFormValid : Fields -> Bool
isNewMasterKeyFormValid fields =
    let
        key =
            Maybe.withDefault "" <| Dict.get "masterKey" fields

        repeat =
            Maybe.withDefault "" <| Dict.get "masterKeyRepeat" fields
    in
        if (String.length key) < 3 then
            False
        else if key /= repeat then
            False
        else
            True
