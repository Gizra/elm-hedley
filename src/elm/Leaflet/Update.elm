module Leaflet.Update where

import Event.Model exposing (Event)
import Leaflet.Model as Leaflet exposing (initialModel, Marker, Model)

init : Model
init =
  initialModel

type Action
  = SelectMarker (Maybe Int)
  | SetMarkers (List Event)
  | ToggleMap
  | UnselectMarker


update : Action -> Model -> Model
update action model =
  case action of
    SelectMarker val ->
      { model | selectedMarker = val }

    SetMarkers events ->
      { model | markers = eventToMarkers events }

    ToggleMap ->
      { model | showMap = (not model.showMap) }

    UnselectMarker ->
      { model | selectedMarker = Nothing }

eventToMarkers : List Event -> List Leaflet.Marker
eventToMarkers events =
  events
    |> List.map (\event -> Leaflet.Marker event.id event.marker.lat event.marker.lng)
