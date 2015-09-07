module User where

import Config exposing (backendUrl)
import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, targetValue)
import Http
import Json.Decode as Json exposing ((:=))
import Login exposing (..)
import String exposing (length)
import Task


import Debug


-- MODEL

type alias Id = Int
type alias AccessToken = String

type User = Anonymous | LoggedIn String

type alias Model =
  { name : User
  , id : Id
  , isFetching : Bool

  -- Child components
  , loginModel : Login.Model
  }


initialModel : Model
initialModel =
  Model Anonymous 0 False (Login.initialModel)

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )


-- UPDATE

type Action
  = GetDataFromServer
  | UpdateDataFromServer (Result Http.Error (Id, String))
  | ChildAction Login.Action


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    GetDataFromServer ->
      let
        url : String
        url = Config.backendUrl ++ "/api/v1.0/me"
      in
        ( { model | isFetching <- True}
        , getJson url model.loginModel.accessToken
        )

    UpdateDataFromServer result ->
      let
        newModel  = { model | isFetching <- False}
      in
        case result of
          Ok (id, name) -> ({newModel | id <- id, name <- LoggedIn name}, Effects.none)
          Err msg -> (newModel, Effects.none)

    ChildAction act ->
      let
        (updatedLoginModel, loginEffects) = Login.update act model.loginModel


        effects =
          case act of
            Login.GetAccessTokenFromServer _ ->
              [ Effects.map ChildAction loginEffects
              , getDataFromServer
              ]
            _ -> [ Effects.map ChildAction loginEffects ]
      in
      ( {model | loginModel <- updatedLoginModel}
      , Effects.batch effects
      )

getDataFromServer : Effects Action
getDataFromServer =
  -- @todo: Get rid of Task.sleep
  Task.sleep (0)
    |> Task.map (\_ -> GetDataFromServer)
    |> Effects.task

-- VIEW

(=>) = (,)

view : Signal.Address Action -> Model -> Html
view address model =
  if model.name == Anonymous
    then
      let
        childAddress =
            Signal.forwardTo address ChildAction
      in
      div [style myStyle]
        [ Login.view childAddress model.loginModel
        ]

    else
  div [style myStyle]
    [ div [] [text ("Welcome " ++ toString(model.name))]
    ]

myStyle : List (String, String)
myStyle =
    [ ("width", "100%")
    , ("height", "40px")
    , ("padding", "10px 0")
    , ("font-size", "2em")
    , ("text-align", "center")
    ]

-- EFFECTS


getJson : String -> Login.AccessToken -> Effects Action
getJson url accessToken =
  let
    encodedUrl = Http.url url [ ("access_token", accessToken) ]
  in
    Http.send Http.defaultSettings
      { verb = "GET"
      , headers = []
      , url = encodedUrl
      , body = Http.empty
      }
      |> Http.fromJson decodeData
      |> Task.toResult
      |> Task.map UpdateDataFromServer
      |> Effects.task


decodeData : Json.Decoder (Id, String)
decodeData =
  let number =
    Json.oneOf [ Json.int, Json.customDecoder Json.string String.toInt ]
  in
  Json.at ["data", "0"]
    <| Json.object2 (,)
      ("id" := number)
      ("label" := Json.string)
