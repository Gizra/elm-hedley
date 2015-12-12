module Pages.Event.Model where

import Event.Model exposing (Event)
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
  , status : Status
  , selectedCompany : Maybe CompanyId
  , selectedEvent : Maybe Int
  , selectedAuthor : Maybe Int
  -- @todo: Make (Maybe String)
  , filterString : String
  , leaflet : Leaflet.Model.Model
  }

initialModel : Model
initialModel =
  { events = []
  , status = Init
  , selectedCompany = Nothing
  , selectedEvent = Nothing
  , selectedAuthor = Nothing
  , filterString = ""
  , leaflet = Leaflet.Model.initialModel
  }
