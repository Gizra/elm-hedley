module Pages.User.Update where

import Company exposing (..)
import ConfigType exposing (BackendConfig)
import Effects exposing (Effects, Never)
import Http exposing (Error)
import String
import Task

import Pages.User.Model as User exposing (..)
import Pages.User.Decoder exposing (..)

type alias UpdateContext =
  { accessToken : AccessToken
  , backendConfig : BackendConfig
  }

update : UpdateContext -> Action -> User.Model -> (User.Model, Effects Action)
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
