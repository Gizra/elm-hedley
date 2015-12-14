module EventCompanyFilter.Update where

import EventCompanyFilter.Model as EventCompanyFilter exposing (initialModel, Model)

-- import Config exposing (cacheTtl)
import Config.Model exposing (BackendConfig)
import Company.Model as Company exposing (Model)
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

type alias Model = EventCompanyFilter.Model

update : Context -> Action -> Model -> (Model, Effects Action)
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
        ( selectedCompany
        , Effects.none
        )
