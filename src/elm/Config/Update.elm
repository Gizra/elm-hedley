module Config.Update where

import Config exposing (backends)
import Config.Model exposing (initialModel, Model)
import Effects exposing (Effects)
import Task exposing (map)
import WebAPI.Location exposing (location)

init : (Model, Effects Action)
init =
  ( initialModel
  , getConfigFromUrl
  )

type Action
  = SetConfig Config.Model.BackendConfig
  | SetError

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    SetConfig backendConfig ->
      ( { model | backendConfig = backendConfig }
      , Effects.none
      )

    SetError ->
      ( { model | error = True }
      , Effects.none
      )


-- EFFECTS

getConfigFromUrl : Effects Action
getConfigFromUrl =
  let
    getAction location =
      let
        config =
          List.filter (\backend -> backend.hostname == location.hostname) backends
          |> List.head
      in
        case config of
          Just val -> SetConfig val
          Nothing -> SetError

    actionTask =
      Task.map getAction WebAPI.Location.location
  in
    Effects.task actionTask
