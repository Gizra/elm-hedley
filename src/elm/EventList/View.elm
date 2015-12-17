module EventList.View (view) where

import EventList.Model as EventList exposing (initialModel, Model)
import EventList.Update exposing (Action)

import Html exposing (a, div, input, text, select, span, li, option, ul, Html)
import Html.Attributes exposing (class, hidden, href, id, placeholder, selected, style, value)
import Html.Events exposing (on, onClick, targetValue)
import String exposing (toInt)

type alias Model = EventCompanyFilter.Model

view : List Company.Model -> Signal.Address Action -> Model -> Html
view companies address model =
  div []
      [ div [class "h2"] [ text "Event list"]
      , (viewFilterString address model)
      , (viewListEvents address model)
      ]

viewFilterString : Signal.Address Action -> Model -> Html
viewFilterString address model =
  div []
    [ input
        [ placeholder "Filter events"
        , value model.filterString
        , on "input" targetValue (Signal.message address << Pages.Event.Update.FilterEvents)
        ]
        []
    ]


viewListEvents : Signal.Address Action -> Model -> Html
viewListEvents address model =
  let
    filteredEvents = filterListEvents model

    hrefVoid =
      href "javascript:void(0);"

    eventSelect event =
      li []
        [ a [ hrefVoid , onClick address (Pages.Event.Update.SelectEvent <| Just event.id) ] [ text event.label ] ]

    eventUnselect event =
      li []
        [ span []
          [ a [ href "javascript:void(0);", onClick address (Pages.Event.Update.UnSelectEvent) ] [ text "x " ]
          , text event.label
          ]
        ]

    getListItem : Event -> Html
    getListItem event =
      case model.selectedEvent of
        Just id ->
          if event.id == id then eventUnselect(event) else eventSelect(event)

        Nothing ->
          eventSelect(event)
  in
    if not <| List.isEmpty filteredEvents
      then
        ul [] (List.map getListItem filteredEvents)
      else
        div [] [ text "No results found"]
