module Pages.User.Update where

import Config.Model exposing (BackendConfig)
import Company.Model as Company exposing (initialModel, Model)
import Effects exposing (Effects, Never)
import Http exposing (Error)
import Pages.User.Model as User exposing (Model)
import Pages.User.Decoder exposing (decode)
import Task exposing (succeed)

type alias Id = Int
type alias AccessToken = String
type alias Model = User.Model

type alias UpdateContext =
  { accessToken : AccessToken
  , backendConfig : BackendConfig
  }

type Action
  = GetDataFromServer
  | NoOp (Maybe ())
  | SetAccessToken AccessToken
  | UpdateDataFromServer (Result Http.Error (Id, String, List Company.Model))

init : (Model, Effects Action)
init =
  ( User.initialModel
  , Effects.none
  )

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
        if model.status == User.Fetching || model.status == User.Fetched
          then
            (model, Effects.none)
          else
            ( { model | status = User.Fetching }
            , getJson url context.accessToken
            )

    UpdateDataFromServer result ->
      let
        model' =
          { model | status = User.Fetched}
      in
        case result of
          Ok (id, name, companies) ->
            ( {model'
                | id = id
                , name = User.LoggedIn name
                , companies = companies
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
            ( { model' | status = User.HttpError msg }
            , effects
            )

    SetAccessToken accessToken ->
      ( {model | accessToken = accessToken}
      , Effects.none
      )

-- Effects

getJson : String -> AccessToken -> Effects Action
getJson url accessToken =
  let
    encodedUrl = Http.url url [ ("access_token", accessToken) ]
  in
    Http.get decode encodedUrl
      |> Task.toResult
      |> Task.map UpdateDataFromServer
      |> Effects.task
