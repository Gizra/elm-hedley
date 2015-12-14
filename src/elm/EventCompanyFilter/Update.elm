module EventCompanyFilter.Update where

import EventCompanyFilter.Model as EventCompanyFilter exposing (initialModel, Model)

-- import Config exposing (cacheTtl)
import ConfigType exposing (BackendConfig)
import Company exposing (Model)
-- import Dict exposing (Dict)
import Effects exposing (Effects)
-- import Html exposing (a, div, input, text, select, span, li, option, ul, Html)
-- import Html.Attributes exposing (class, hidden, href, id, placeholder, selected, style, value)
-- import Html.Events exposing (on, onClick, targetValue)
-- import Http
-- import Json.Decode as Json exposing ((:=))
-- import Leaflet exposing (Model, initialModel, Marker, update)
-- import RouteHash exposing (HashUpdate)
-- import String exposing (length)
import Task  exposing (succeed)
-- import TaskTutorial exposing (getCurrentTime)
-- import Time exposing (Time)

init : (EventCompanyFilter.Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )


type Action
  = SelectCompany (Maybe Int)

type alias Context =
  { accessToken : String
  , backendConfig : BackendConfig
  , companies : List Company.Model
  }

update : Context -> Action -> EventCompanyFilter.Model -> (EventCompanyFilter.Model, Effects Action)
update context action model =
  case action of
    SelectCompany maybeCompanyId ->
      let
        isValidCompany val =
          context.companies
            |> List.filter (\company -> company.id == val)
            |> List.length


        selectedCompany =
          case maybeCompanyId of
            Just val ->
              -- Make sure the given company ID is a valid one.
              if ((isValidCompany val) > 0)
                then Just val
                else Nothing
            Nothing ->
              Nothing
      in
        ( { model | selectedCompany = selectedCompany }
        , Task.succeed (GetData selectedCompany) |> Effects.task
        )
