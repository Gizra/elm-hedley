module Pages.User.Update where

import ConfigType exposing (BackendConfig)
import Effects exposing (Effects, Never)
import Http exposing (Error)
import Pages.User.Model as User exposing (AccessToken, Model)
import Pages.User.Decoder exposing (decode)
import Task exposing (succeed)

type alias Action = User.Action

type alias UpdateContext =
  { accessToken : AccessToken
  , backendConfig : BackendConfig
  }

update : UpdateContext -> User.Action -> User.Model -> (User.Model, Effects Action)
update context action model =
  case action of
    User.NoOp _ ->
      (model, Effects.none)

    User.GetDataFromServer ->
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
            ( { model | status <- User.Fetching }
            , getJson url context.accessToken
            )

    User.UpdateDataFromServer result ->
      let
        model' =
          { model | status <- User.Fetched}
      in
        case result of
          Ok (id, name, companies) ->
            ( {model'
                | id <- id
                , name <- User.LoggedIn name
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
                      then Task.succeed (User.SetAccessToken "") |> Effects.task
                      else Effects.none

                  _ ->
                    Effects.none

            in
            ( { model' | status <- User.HttpError msg }
            , effects
            )

    User.SetAccessToken accessToken ->
      ( {model | accessToken <- accessToken}
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
      |> Task.map User.UpdateDataFromServer
      |> Effects.task
