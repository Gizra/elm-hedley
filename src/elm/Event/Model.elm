module Event.Model where

import Http exposing (Error)
import Time exposing (Time)

type alias Id = Int
type alias CompanyId = Int

type Status =
  Init
  | Fetching (Maybe CompanyId)
  | Fetched (Maybe CompanyId) Time.Time
  | HttpError Http.Error

type alias Marker =
  { lat: Float
  , lng : Float
  }

type alias Author =
  { id : Id
  , name : String
  }

type alias Event =
  { id : Id
  , label : String
  , marker : Marker
  , author : Author
  }

type alias Model =
  { events : List Event
  , status : Status
  }

initialModel : Model
initialModel =
  { events = []
  , status = Init
  }
