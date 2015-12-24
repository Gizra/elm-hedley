module EventList.Update where

import Event.Model exposing (Event)
import EventList.Model as EventList exposing (initialModel, Model)

type Action
  = FilterEvents String
  -- Select event might get values from JS (i.e. selecting a leaflet marker)
  -- so we allow passing a Maybe Int, instead of just Int.
  | SelectEvent (Maybe Int)
  | UnSelectEvent

type alias Model = EventList.Model

init : Model
init = initialModel


update : List Event -> Action -> Model -> Model
update events action model =
  case action of
    FilterEvents val ->
      { model | filterString = val }

    SelectEvent val ->
      { model | selectedEvent = val }

    UnSelectEvent ->
      { model | selectedEvent = Nothing }
