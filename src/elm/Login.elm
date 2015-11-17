module Login where

import Base64 exposing (encode)
import ConfigType exposing (BackendConfig)
import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onSubmit, targetValue)
import Http exposing (Error)
import Json.Decode as JD exposing ((:=))
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

type UserMessage
  = None
  | Error String

type Status
  = Init
  | Fetching
  | Fetched
  | HttpError Http.Error

type alias Model =
  { accessToken: AccessToken
  , hasAccessTokenInStorage : Bool
  , loginForm : LoginForm
  , status : Status
  , userMessage : UserMessage
  }

initialModel : Model
initialModel =
  { accessToken = ""
  -- We start by assuming there's already an access token it the localStorage.
  -- While this property is set to True, the login form will not appear.
  , hasAccessTokenInStorage = True
  , loginForm = LoginForm "demo" "1234"
  , status = Init
  , userMessage = None
  }


init : (Model, Effects Action)
init =
  ( initialModel
  -- Try to get an existing access token.
  , getInputFromStorage
  )


-- UPDATE

type Action
  = UpdateAccessTokenFromServer (Result Http.Error AccessToken)
  | UpdateAccessTokenFromStorage (Result String AccessToken)
  | UpdateName String
  | UpdatePass String
  | SetAccessToken AccessToken
  | SetUserMessage UserMessage
  | SubmitForm

type alias UpdateContext =
  { backendConfig : BackendConfig
  }

type alias ViewContext =
  { backendConfig : BackendConfig
  }

update : UpdateContext -> Action -> Model -> (Model, Effects Action)
update context action model =
  case action of
    UpdateName name ->
      let
        loginForm = model.loginForm
        updatedLoginForm = { loginForm | name <- name }
      in
        ( { model | loginForm <- updatedLoginForm }
        , Effects.none
        )

    UpdatePass pass ->
      let
        loginForm = model.loginForm
        updatedLoginForm = { loginForm | pass <- pass }
      in
        ( {model | loginForm <- updatedLoginForm }
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
        if model.status == Fetching || model.status == Fetched
          then
            (model, Effects.none)
          else
            ( { model | status <- Fetching }
            , Effects.batch
              [ Task.succeed (SetUserMessage None) |> Effects.task
              , getJson url credentials
              ]
            )

    SetAccessToken token ->
      ( { model
        | accessToken <- token
        -- This is a good time also to hide the password.
        , loginForm <- LoginForm model.loginForm.name ""
        }
      , Effects.none
      )

    SetUserMessage userMessage ->
      ( { model | userMessage <- userMessage }
      , Effects.none
      )

    UpdateAccessTokenFromServer result ->
      case result of
        Ok token ->
          ( { model | status <- Fetched }
          , Task.succeed (SetAccessToken token) |> Effects.task
          )
        Err err ->
          let
            message =
              getErrorMessageFromHttpResponse err
          in
            ( { model | status <- HttpError err }
            , Task.succeed (SetUserMessage <| Error message) |> Effects.task
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

getErrorMessageFromHttpResponse : Http.Error -> String
getErrorMessageFromHttpResponse err =
  case err of
    Http.Timeout ->
      "Connection has timed out"

    Http.BadResponse code _ ->
      if | code == 401 -> "Wrong username or password"
         | code == 429 -> "Too many login requests with the wrong username or password. Wait a few hours before trying again"
         | code >= 500 -> "Some error has occured on the server"
         | otherwise -> "Unknow error has occured"

    Http.NetworkError ->
      "A network error has occured"

    _ ->
      "Unknow error has occured"


getInputFromStorage : Effects Action
getInputFromStorage =
  Storage.getItem "access_token" JD.string
    |> Task.toResult
    |> Task.map UpdateAccessTokenFromStorage
    |> Effects.task



-- VIEW

view : ViewContext -> Signal.Address Action -> Model -> Html
view context address model =
  let
    modelForm =
      model.loginForm

    isFormEmpty =
      String.isEmpty modelForm.name || String.isEmpty modelForm.pass

    isFetchStatus =
      model.status == Fetching || model.status == Fetched

    githubClientId =
      (.backendConfig >> .githubClientId) context

    githubUrl =
      "https://github.com/login/oauth/authorize?client_id=" ++ githubClientId ++ "&scope=user:email"


    githubLogin =
      div
      [ class "btn btn-lg btn-primary btn-block"]
      [ a
        [ href githubUrl]
        [ i [ class "fa fa-github", style [("margin-right", "10px")] ] []
        , span [] [ text "Login with GitHub" ]
        ]
      ]

    loginForm =
      Html.form
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
        , githubLogin
        , div
          [ style [("margin-bottom", "20px"), ("margin-top", "20px"), ("text-align", "center")] ]
          [ text "OR" ]
        , div
            [ class "input-group" ]
            [ span
                [ class "input-group-addon" ]
                [ i [ class "glyphicon glyphicon-user" ] [] ]
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
              [ i [ class "fa fa-lock fa-lg" ] [] ]
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

    spinner =
      i [ class "fa fa-spinner fa-spin" ] []

    userMessage =
      case model.userMessage of
        None ->
          div [] []
        Error message ->
          div [ style [("text-align", "center")]] [ text message ]

  in
    div [ id "login-page" ] [
      hr [] []
      , div
          [ class "container" ]
          [ userMessage
          , div
              [ class "wrapper" ]
              [ loginForm
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
