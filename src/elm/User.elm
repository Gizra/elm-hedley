module User where

import Company exposing (..)
import ConfigType exposing (BackendConfig)
import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http exposing (Error)
import Json.Decode as Json exposing ((:=))
import String exposing (length)
import Task

import Debug

-- MODEL

type alias Id = Int
type alias AccessToken = String

type User = Anonymous | LoggedIn String

type Status =
  Init
  | Fetching
  | Fetched
  | HttpError Http.Error

type alias Model =
  { name : User
  , id : Id
  , status : Status
  , accessToken : AccessToken

  -- Child components
  , companies : List Company.Model
  }


initialModel : Model
initialModel =
  { name = Anonymous
  , id = 0
  , status = Init
  , accessToken = ""

  -- Child components
  , companies = [Company.initialModel]
  }

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )


-- UPDATE

type Action
  = GetDataFromServer
  | SetAccessToken AccessToken
  | UpdateDataFromServer (Result Http.Error (Id, String, List Company.Model))

  -- NoOp actions
  | NoOp (Maybe ())

type alias UpdateContext =
  { accessToken : AccessToken
  , backendConfig : BackendConfig
  }

update : UpdateContext -> Action -> Model -> (Model, Effects Action)
update context action model =
  case action of
    NoOp _ ->
      (model, Effects.none)

    GetDataFromServer ->
      let
        backendUrl =
          (.backendConfig >> .backendUrl) context

        url =
          backendUrl ++ "/api/v1.0/me"
      in
        if model.status == Fetching || model.status == Fetched
          then
            (model, Effects.none)
          else
            ( { model | status <- Fetching }
            , getJson url context.accessToken
            )

    UpdateDataFromServer result ->
      let
        model' =
          { model | status <- Fetched}
      in
        case result of
          Ok (id, name, companies) ->
            ( {model'
                | id <- id
                , name <- LoggedIn name
                , companies <- companies
              }
            , Effects.none
            )
          Err msg ->
            let
              effects =
                case msg of
                  Http.BadResponse code _ ->
                    if (code == 401)
                      -- Token is wrong, so remove any existing one.
                      then Task.succeed (SetAccessToken "") |> Effects.task
                      else Effects.none

                  _ ->
                    Effects.none

            in
            ( { model' | status <- HttpError msg }
            , effects
            )

    SetAccessToken accessToken ->
      ( {model | accessToken <- accessToken}
      , Effects.none
      )


-- Determines if a call to the server should be done, based on having an access
-- token present.
isAccessTokenInStorage : Result err String -> Bool
isAccessTokenInStorage result =
  case result of
    -- If token is empty, no need to call the server.
    Ok token ->
      if String.isEmpty token then False else True

    Err _ ->
      False


-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  case model.name of
    Anonymous ->
      div [] [ text "This is wrong - anon user cannot reach this!"]

    LoggedIn name ->
      let
        italicName : Html
        italicName =
          em [] [text name]
      in
        div [class "container"]
          [ div [] [ text "Welcome ", italicName ]
          , div [] [ text "Your companies are:"]
          , ul  [] (List.map viewCompanies model.companies)
          ]

viewCompanies : Company.Model -> Html
viewCompanies company =
  li [] [ text company.label ]

-- EFFECTS


getJson : String -> AccessToken -> Effects Action
getJson url accessToken =
  let
    encodedUrl = Http.url url [ ("access_token", accessToken) ]
  in
    Http.get decodeData encodedUrl
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
