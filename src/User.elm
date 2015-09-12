module User where

import Company exposing (..)
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

-- MODEL

type alias Id = Int
type alias AccessToken = String

type User = Anonymous | LoggedIn String

type alias Model =
  { name : User
  , id : Id
  , isFetching : Bool
  , accessToken : AccessToken

  -- Child components
  , loginModel : Login.Model
  , companies : List Company.Model
  }


initialModel : Model
initialModel =
  Model Anonymous 0 False "" Login.initialModel [Company.initialModel]

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )


-- UPDATE

type Action
  = GetDataFromServer
  | UpdateDataFromServer (Result Http.Error (Id, String, List Company.Model))
  | ChildAction Login.Action
  | SetAccessToken AccessToken


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
          Ok (id, name, companies) ->
            ( {newModel
                | id <- id
                , name <- LoggedIn name
                , companies <- companies
              }
            , Effects.none
            )
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
      ( {model | loginModel <- updatedLoginModel, accessToken <- updatedLoginModel.accessToken}
      , Effects.batch effects
      )

    SetAccessToken accessToken ->
      ( {model | accessToken <- accessToken}
      , Effects.none
      )

getDataFromServer : Effects Action
getDataFromServer =
  Task.succeed GetDataFromServer
    |> Effects.task

-- VIEW

(=>) = (,)

view : Signal.Address Action -> Model -> Html
view address model =
  case model.name of
    Anonymous ->
      let
        childAddress =
            Signal.forwardTo address ChildAction
      in
        div []
          [ Login.view childAddress model.loginModel
          ]

    LoggedIn name ->
      let
        italicName : Html
        italicName =
          em [] [text name]
      in
      div []
        [ div [] [ text "Welcome ", italicName ]
        , div [] [ text "Your companies are:"]
        , ul  [] (List.map viewCompanies model.companies)
        , div  [] [text (toString model.accessToken)]
        ]

viewCompanies : Company.Model -> Html
viewCompanies company =
  li [] [ text company.label ]

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


decodeData : Json.Decoder (Id, String, List Company.Model)
decodeData =
  let
    -- Cast String to Int.
    number : Json.Decoder Int
    number =
      Json.oneOf [ Json.int, Json.customDecoder Json.string String.toInt ]

    company =
      Json.object2 Company.Model
        ("id" := number)
        ("label" := Json.string)
  in
  Json.at ["data", "0"]
    <| Json.object3 (,,)
      ("id" := number)
      ("label" := Json.string)
      ("companies" := Json.list company)
