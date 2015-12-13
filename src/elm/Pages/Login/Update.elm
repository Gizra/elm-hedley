module Pages.Login.Update where

import Pages.Login.Model exposing (initialModel, Model)

import Base64 exposing (encode)
import Config.Model exposing (BackendConfig)
import Effects exposing (Effects)
import Http exposing (Error)
import Json.Decode as JD exposing ((:=))
import Storage exposing (getItem)
import Task exposing  (Task)
import Utils.Http exposing (getErrorMessageFromHttpResponse)

type alias AccessToken = String

init : (Model, Effects Action)
init =
  ( initialModel
  -- Try to get an existing access token.
  , getInputFromStorage
  )

type Action
  = UpdateAccessTokenFromServer (Result Http.Error AccessToken)
  | UpdateAccessTokenFromStorage (Result String AccessToken)
  | UpdateName String
  | UpdatePass String
  | SetAccessToken AccessToken
  | SetUserMessage Pages.Login.Model.UserMessage
  | SubmitForm

type alias Context =
  { backendConfig : BackendConfig
  }

update : Context -> Action -> Model -> (Model, Effects Action)
update context action model =
  case action of
    UpdateName name ->
      let
        loginForm = model.loginForm
        updatedLoginForm = { loginForm | name = name }
      in
        ( { model | loginForm = updatedLoginForm }
        , Effects.none
        )

    UpdatePass pass ->
      let
        loginForm = model.loginForm
        updatedLoginForm = { loginForm | pass = pass }
      in
        ( {model | loginForm = updatedLoginForm }
        , Effects.none
        )

    SubmitForm ->
      let
        backendUrl =
          (.backendConfig >> .backendUrl) context

        url =
          backendUrl ++ "/api/login-token"

        credentials : String
        credentials = encodeCredentials(model.loginForm.name, model.loginForm.pass)
      in
        if model.status == Pages.Login.Model.Fetching || model.status == Pages.Login.Model.Fetched
          then
            (model, Effects.none)
          else
            ( { model | status = Pages.Login.Model.Fetching }
            , Effects.batch
              [ Task.succeed (SetUserMessage Pages.Login.Model.None) |> Effects.task
              , getJson url credentials
              ]
            )

    SetAccessToken token ->
      ( { model
        | accessToken = token
        -- This is a good time also to hide the password.
        , loginForm = Pages.Login.Model.LoginForm model.loginForm.name ""
        }
      , Effects.none
      )

    SetUserMessage userMessage ->
      ( { model | userMessage = userMessage }
      , Effects.none
      )

    UpdateAccessTokenFromServer result ->
      case result of
        Ok token ->
          ( { model | status = Pages.Login.Model.Fetched }
          , Task.succeed (SetAccessToken token) |> Effects.task
          )
        Err err ->
          let
            message =
              getErrorMessageFromHttpResponse err
          in
            ( { model | status = Pages.Login.Model.HttpError err }
            , Task.succeed (SetUserMessage <| Pages.Login.Model.Error message) |> Effects.task
            )

    UpdateAccessTokenFromStorage result ->
      case result of
        Ok token ->
          ( model
          , Task.succeed (SetAccessToken token) |> Effects.task
          )
        Err err ->
          -- There was no access token in the storage, so show the login form
          ( { model | hasAccessTokenInStorage = False }
          , Effects.none
          )


getInputFromStorage : Effects Action
getInputFromStorage =
  Storage.getItem "access_token" JD.string
    |> Task.toResult
    |> Task.map UpdateAccessTokenFromStorage
    |> Effects.task


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
