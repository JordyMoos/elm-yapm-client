port module Main exposing (main)

import Basics exposing (..)
import Html
import Time
import Mouse
import Auth
import Unauth


type PageState
    = Unauthorized Unauth.Model
    | Authorized Auth.Model


type alias Model =
    { config : Flags
    , state : PageState
    }


initModel : Flags -> Model
initModel flags =
    { config = flags
    , state = Unauth.initModel
    }


type Msg
    = AuthorizedMsg Auth.Msg
    | AuthorizedMsg Unauth.Msg


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( subModel, subCmd ) =
            Unauth.init
    in
        ( Model flags (Unauthorized subModel), Cmd.map UnauthorizedMsg subCmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        Authorized _ ->
            Auth.subscriptions

        Unauthorized _ ->
            Unauth.subscriptions


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        toPage : (a -> Model) -> (b -> Msg) -> (b -> a -> ( a, Cmd b )) -> b -> a -> ( Model, Cmd Msg )
        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
                ( { model | state = toModel newModel }, Cmd.map toMsg newCmd )
    in
        case ( msg, model.state ) of
            ( AuthorizedMsg msg, Authorized authModel ) ->
                toPage Authorized AuthorizedMsg Auth.update msg authModel

            ( UnauthorizedMsg msg, Unauthorized autModel ) ->
                toPage Unauthorized UnauthorizedMsg Unauth.update msg unauthModel

            -- bips for wrong message in current state
            ( _, _ ) ->
                model ! []


view : Model -> Html Msg
view model =
    case model.state of
        Unauthorized unauth ->
            Unauth.view ( model.config, unauth ) |> Html.map Unauthorized

        Authorized auth ->
            HtAuth.view ( model.config, auth ) |> Html.map Authorized



-- These models should see a better place in life


type alias Library =
    { blob : String
    , libraryVersion : Int
    , apiVersion : Int
    , modified : Int
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


type alias ElementId =
    String


type alias PasswordId =
    Int


type alias MasterKey =
    String
