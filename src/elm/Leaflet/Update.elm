module Leaflet.Update where

import Leaflet.Model exposing (initialModel, Model)

import Effects exposing (Effects)

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )

type Action
  = ToggleMap
  | SelectMarker (Maybe Int)
  | UnselectMarker


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    ToggleMap ->
      ( { model | showMap = (not model.showMap) }
      , Effects.none
      )

    SelectMarker val ->
      ( { model | selectedMarker = val }
      , Effects.none
      )

    UnselectMarker ->
      ( { model | selectedMarker = Nothing }
      , Effects.none
      )
