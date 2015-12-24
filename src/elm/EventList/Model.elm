module EventList.Model where

type alias Model =
  { filterString : String
  , selectedEvent : Maybe Int
  }

initialModel : Model
initialModel =
  { filterString = ""
  , selectedEvent = Nothing
  }
