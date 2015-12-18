module EventList.Update where

import EventList.Model as EventList exposing (initialModel, Model)

init : Model
init = initialModel

type Action
  = FilterEvents String
  -- Select event might get values from JS (i.e. selecting a leaflet marker)
  -- so we allow passing a Maybe Int, instead of just Int.
  | SelectEvent (Maybe Int)
  | UnSelectEvent


update : Action -> Model -> Model
update action model =
  case action of
    FilterEvents val ->
      let
        model' = { model | filterString = val }

        -- effects =
        --   case model.selectedEvent of
        --     Just id ->
        --       -- Determine if the selected event is visible (i.e. not filtered
        --       -- out).
        --       let
        --         isSelectedEvent =
        --           filterListEvents model'
        --             |> List.filter (\event -> event.id == id)
        --             |> List.length
        --       in
        --         if isSelectedEvent > 0 then Effects.none else Task.succeed UnSelectEvent |> Effects.task
        --
        --     Nothing ->
        --       Effects.none
      in
        model'

    SelectEvent val ->
      { model | selectedEvent = val }

    UnSelectEvent ->
      { model | selectedEvent = Nothing }

-- -- Build the Leaflet's markers data from the events
-- leafletMarkers : Model -> List Leaflet.Model.Marker
-- leafletMarkers model =
--   filterListEvents model
--     |> List.map (\event -> Leaflet.Model.Marker event.id event.marker.lat event.marker.lng)
--
-- -- In case an author or string-filter is selected, filter the events.
-- filterListEvents : Model -> List Event
-- filterListEvents model =
--   let
--     authorFilter : List Event -> List Event
--     authorFilter events =
--       case model.eventAuthorFilter of
--         Just id ->
--           List.filter (\event -> event.author.id == id) events
--
--         Nothing ->
--           events
--
--     stringFilter : List Event -> List Event
--     stringFilter events =
--       if String.length (String.trim model.filterString) > 0
--         then
--           List.filter (\event -> String.contains (String.trim (String.toLower model.filterString)) (String.toLower event.label)) events
--
--         else
--           events
--
--   in
--     authorFilter model.events
--      |> stringFilter
