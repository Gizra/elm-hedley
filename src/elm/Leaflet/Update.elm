module Leaflet.Update where

import Event.Model exposing (Event)
import Effects exposing (Effects)
import Leaflet.Model as Leaflet exposing (initialModel, Marker, Model, MountStatus)

init : Model
init =
  initialModel

type Action
  = SelectMarker (Maybe Int)
  | SetMarkers (List Event)
  | SetMountStatus MountStatus
  | ToggleMap
  | UnselectMarker



update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    SelectMarker val ->
      ( { model | selectedMarker = val }
      , Effects.none
      )

    SetMarkers events ->
      ( { model | markers = eventToMarkers events }
      , Effects.none
      )

    SetMountStatus status ->
      ( model
      , Effects.none
      )

    ToggleMap ->
      ( { model | showMap = (not model.showMap) }
      , Effects.none
      )

    UnselectMarker ->
      ( { model | selectedMarker = Nothing }
      , Effects.none
      )

eventToMarkers : List Event -> List Leaflet.Marker
eventToMarkers events =
  events
    |> List.map (\event -> Leaflet.Marker event.id event.marker.lat event.marker.lng)
