module EventList.Update where

import EventList.Model as EventList exposing (initialModel, Model)

import Effects exposing (Effects)

init : (EventCompanyFilter.Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )


type Action
  = FilterEvents String
  -- Select event might get values from JS (i.e. selecting a leaflet marker)
  -- so we allow passing a Maybe Int, instead of just Int.
  | SelectEvent (Maybe Int)
  | UnSelectEvent


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    FilterEvents val ->
      let
        model' = { model | filterString = val }

        leaflet = model.leaflet
        leaflet' = { leaflet | markers = (leafletMarkers model')}

        effects =
          case model.selectedEvent of
            Just id ->
              -- Determine if the selected event is visible (i.e. not filtered
              -- out).
              let
                isSelectedEvent =
                  filterListEvents model'
                    |> List.filter (\event -> event.id == id)
                    |> List.length
              in
                if isSelectedEvent > 0 then Effects.none else Task.succeed UnSelectEvent |> Effects.task

            Nothing ->
              Effects.none
      in
        ( { model
          | filterString = val
          , leaflet = leaflet'
          }
        , effects
        )

    SelectEvent val ->
      case val of
        Just id ->
          ( { model | selectedEvent = Just id }
          , Task.succeed (ChildLeafletAction <| Leaflet.Update.SelectMarker <| Just id) |> Effects.task
          )
        Nothing ->
          (model, Task.succeed UnSelectEvent |> Effects.task)

    UnSelectEvent ->
      ( { model | selectedEvent = Nothing }
      , Task.succeed (ChildLeafletAction <| Leaflet.Update.SelectMarker Nothing) |> Effects.task
      )
