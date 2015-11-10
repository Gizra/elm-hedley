module Login where

import Base64 exposing (encode)
import Config exposing (backendUrl)
import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onSubmit, targetValue)
import Http
import Json.Encode as JE exposing (string, Value)
import Json.Decode as JD exposing ((:=))
import RouteHash exposing (HashUpdate)
import Storage exposing (..)
import String exposing (length)
import Task


import Debug


-- MODEL

type alias AccessToken = String

type alias LoginForm =
  { name: String
  , pass : String
  }

type Status =
  Init
  | Fetching
  | Fetched
  | HttpError Http.Error

type alias Model =
  { accessToken: AccessToken
  , loginForm : LoginForm
  , status : Status
  , hasAccessTokenInStorage : Bool
  }

initialModel : Model
initialModel =
  { accessToken = ""
  , loginForm = LoginForm "demo" "1234"
  , status = Init
  -- We start by assuming there's already an access token it the localStorage.
  -- While this property is set to True, the login form will not appear.
  , hasAccessTokenInStorage = True
  }


init : (Model, Effects Action)
init =
  ( initialModel
  -- Try to get an existing access token.
  , getInputFromStorage
  )


-- UPDATE

type Action
  = NoOp (Result AccessToken ())
  | UpdateName String
  | UpdatePass String
  | SubmitForm
  | UpdateAccessTokenFromServer (Result Http.Error AccessToken)

  -- Storage
  | SetAccessToken AccessToken
  | UpdateAccessTokenFromStorage (Result String AccessToken)


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
        if model.status == Fetching || model.status == Fetched
          then
            (model, Effects.none)
          else
            ( { model
              | status <- Fetching
              -- Hide the password.
              , loginForm <- LoginForm model.loginForm.name ""
              }
            , getJson url credentials
            )

    NoOp result ->
      (model, Effects.none)

    SetAccessToken token ->
      ( { model | accessToken <- token }
      , sendInputToStorage token
      )

    UpdateAccessTokenFromServer result ->
      case result of
        Ok token ->
          ( { model | status <- Fetched }
          , Task.succeed (SetAccessToken token) |> Effects.task
          )
        Err msg ->
          ( { model | status <- HttpError msg }
          , Effects.none
          )

    UpdateAccessTokenFromStorage result ->
      case result of
        Ok token ->
          ( model
          , Task.succeed (SetAccessToken token) |> Effects.task
          )
        Err err ->
          -- There was no access token in the storage, so show the login form
          ( { model | hasAccessTokenInStorage <- False }
          , Effects.none
          )


sendInputToStorage : String -> Effects Action
sendInputToStorage s =
  Storage.setItem "access_token" (JE.string s)
    |> Task.toResult
    |> Task.map NoOp
    |> Effects.task

getInputFromStorage : Effects Action
getInputFromStorage =
  Storage.getItem "access_token" JD.string
    |> Task.toResult
    |> Task.map UpdateAccessTokenFromStorage
    |> Effects.task



-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  let
    modelForm =
      model.loginForm

    isFormEmpty =
      String.isEmpty modelForm.name || String.isEmpty modelForm.pass

    isFetchStatus =
      model.status == Fetching || model.status == Fetched

    spinner =
      i [ class "fa fa-spinner fa-spin" ] []

  in
    div [ id "login-page" ] [
      hr [] []
      , div [ class "container" ] [
        div [ class "wrapper" ]
          [ Html.form
            [ onSubmit address SubmitForm
            , action "javascript:void(0);"
            , class "form-signin"
            -- Don't show the form while checking for the access token from the
            -- storage.
            , hidden model.hasAccessTokenInStorage
            ]
            -- Form title
            [ h2 [] [ text "Please login" ]
            -- UserName
            , div
              [ class "input-group" ]
              [ span
                [ class "input-group-addon"]
                [ i [ class "glyphicon glyphicon-user" ] []
              ]
              , input
                [ type' "text"
                , class "form-control"
                , placeholder "Name"
                , value model.loginForm.name
                , on "input" targetValue (Signal.message address << UpdateName)
                , size 40
                , required True
                , disabled (isFetchStatus)
                ]
                []
               ]
            -- Password
            , div
              [ class "input-group"]
              [ span
                [ class "input-group-addon" ]
                [ i [ class "fa fa-lock fa-lg" ] []
              ]
              , input
                [ type' "password"
                , class "form-control"
                , placeholder "Password"
                , value modelForm.pass
                , on "input" targetValue (Signal.message address << UpdatePass)
                , size 40
                , required True
                , disabled (isFetchStatus)
                ]
                []
               ]
            -- Submit button
            , button
              [ onClick address SubmitForm
              , class "btn btn-lg btn-primary btn-block"
              , disabled (isFetchStatus || isFormEmpty)
              ]
            [ span [ hidden <| not isFetchStatus] [ spinner ]
            , span [ hidden isFetchStatus ] [ text "Login" ] ]
            ]
            , div
              [ class "text-center"
              , hidden (not (model.status == Fetching) && not model.hasAccessTokenInStorage) ]
              [ text "Loading ..." ]
          ]
        ]
        , hr [] []
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
    |> Task.map UpdateAccessTokenFromServer
    |> Effects.task


decodeAccessToken : JD.Decoder AccessToken
decodeAccessToken =
  JD.at ["access_token"] <| JD.string

-- ROUTER

delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
  Just <| RouteHash.set []

location2action : List String -> List Action
location2action list =
  []
