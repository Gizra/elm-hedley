module Login where

import Base64 exposing (encode)
import Config exposing (backendUrl)
import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onSubmit, targetValue)
import Http
import Json.Decode as Json exposing ((:=))
import String exposing (length)
import Task


import Debug


-- MODEL

type alias AccessToken = String

type alias LoginForm =
  { name: String
  ,  pass : String
  }

type Status =
  Init
  | HttpError Http.Error

type alias Model =
  -- @todo: accessToken: (Maybe AccessToken)
  { accessToken: AccessToken
  , loginForm : LoginForm
  , isFetching : Bool
  , status : Status
  }

initialModel : Model
initialModel =
  Model "" (LoginForm "demo" "1234") False Init


init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )


-- UPDATE

type Action
  = UpdateName String
  | UpdatePass String
  | SubmitForm
  | GetAccessTokenFromServer (Result Http.Error AccessToken)


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    UpdateName name ->
      let
        loginForm = model.loginForm
        updatedLoginForm = { loginForm | name <- name }
      in
      ({model | loginForm <- updatedLoginForm }, Effects.none)

    UpdatePass pass ->
      let
        loginForm = model.loginForm
        updatedLoginForm = { loginForm | pass <- pass }
      in
      ({model | loginForm <- updatedLoginForm }, Effects.none)

    SubmitForm ->
      let
        url : String
        url = Config.backendUrl ++ "/api/login-token"

        credentials : String
        credentials = encodeCredentials(model.loginForm.name, model.loginForm.pass)
      in
      ( { model | isFetching <- True}
      , getJson url credentials
      )

    GetAccessTokenFromServer result ->
      let
        newModel  = { model | isFetching <- False}
      in
        case result of
          Ok accessToken ->
            ({newModel | accessToken <- accessToken}, Effects.none)
          Err msg ->
            (
            {newModel | status <- HttpError msg }
            , Effects.none)



-- VIEW

(=>) = (,)

view : Signal.Address Action -> Model -> Html
view address model =
  let
    modelForm = model.loginForm
  in
  div [class "container"]
    [ Html.form
      [ action "javascript:none"
      , onSubmit address SubmitForm
      ]
      [
    -- Name
    input
        [ type' "text"
        , placeholder "Name"
        , value model.loginForm.name
        , on "input" targetValue (Signal.message address << UpdateName)
        , size 40
        , required True
        ]
        []
    -- Password
    , input
        [ type' "password"
        , placeholder "Password"
        , value modelForm.pass
        , on "input" targetValue (Signal.message address << UpdatePass)
        , size 40
        , required True
        ]
        []
    ]
    , button [ onClick address SubmitForm, disabled ((String.length modelForm.name == 0) || (String.length modelForm.pass == 0)) ] [ text "Login" ]
    , div [hidden (model.isFetching == False)] [ text "Loading ..."]
    ]

-- EFFECTS

encodeCredentials : (String, String) -> String
encodeCredentials (name, pass) =
  let
     base64 = Base64.encode(name ++ ":" ++ pass)
  in
    case base64 of
     Ok result -> result
     Err err -> ""

getJson : String -> String -> Effects Action
getJson url credentials =
  Http.send Http.defaultSettings
    { verb = "GET"
    , headers = [("Authorization", "Basic " ++ credentials)]
    , url = url
    , body = Http.empty
    }
    |> Http.fromJson decodeAccessToken
    |> Task.toResult
    |> Task.map GetAccessTokenFromServer
    |> Effects.task


decodeAccessToken : Json.Decoder AccessToken
decodeAccessToken =
  Json.at ["access_token"] <| Json.string
