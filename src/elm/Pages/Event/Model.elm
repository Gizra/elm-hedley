module Pages.Event.Model where

import Event.Model exposing (Event)
import EventAuthorFilter.Model as EventAuthorFilter exposing (initialModel, Model)
import EventCompanyFilter.Model as EventCompanyFilter exposing (initialModel, Model)
import EventList.Model as EventList exposing (initialModel, Model)

import Http exposing (Error)
import Leaflet.Model exposing (initialModel, Model)
import Time exposing (Time)

type alias Id = Int
type alias CompanyId = Int

type Status =
  Init
  | Fetching (Maybe CompanyId)
  | Fetched (Maybe CompanyId) Time.Time
  | HttpError Http.Error

type alias Model =
  { events : List Event
  , eventList: EventList.Model
  , status : Status
  , eventCompanyFilter : EventCompanyFilter.Model
  , eventAuthorFilter : EventAuthorFilter.Model
  , leaflet : Leaflet.Model.Model
  }

initialModel : Model
initialModel =
  { events = []
  , eventList = EventList.initialModel
  , status = Init
  , eventCompanyFilter = EventCompanyFilter.initialModel
  , eventAuthorFilter = EventAuthorFilter.initialModel
  , leaflet = Leaflet.Model.initialModel
  }
