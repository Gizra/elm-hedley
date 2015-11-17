module ConfigManager where

import Config exposing (backends)
import ConfigType exposing (BackendConfig, initialBackendConfig)
import Effects exposing (Effects)
import Task exposing (map)
import WebAPI.Location exposing (location)

type Status
  = Init
  | Error

type alias Model =
  { backendConfig : BackendConfig
  , status : Status
  }

initialModel : Model
initialModel =
  { backendConfig = initialBackendConfig
  , status = Init
  }

init : (Model, Effects Action)
init =
  ( initialModel
  , getConfigFromUrl
  )

-- UPDATE

type Action
  = SetConfig BackendConfig
  | SetStatus Status

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    SetConfig backendConfig ->
      ( { model | backendConfig <- backendConfig }
      , Effects.none
      )

    SetStatus status ->
      ( { model | status <- status }
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
          Nothing -> SetStatus Error

    actionTask =
      Task.map getAction WebAPI.Location.location
  in
    Effects.task actionTask
