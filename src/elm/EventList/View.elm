module EventList.View (view) where

import Event.Model as Event exposing (Event)
import EventList.Model as EventList exposing (initialModel, Model)
import EventList.Update exposing (Action)
import EventList.Utils exposing (filterEventsByString)

import Html exposing (h3, a, i, div, input, text, select, span, li, option, ul, Html)
import Html.Attributes exposing (class, hidden, href, id, placeholder, selected, style, value)
import Html.Events exposing (on, onClick, targetValue)

type alias Model = EventList.Model

view : List Event -> Signal.Address Action -> Model -> Html
view events address model =
  div
    [ id "events"
    , class "wrapper -suffix" ]
    [ h3
      [ class "title" ]
      [ i [ class "fa fa-map-marker" ] []
      , text <| " " ++ "Event List"
      ]
      , (viewFilterString address model)
      , (viewListEvents events address model)
      ]


viewFilterString : Signal.Address Action -> Model -> Html
viewFilterString address model =
  div []
    [ input
        [ class "search form-control"
        , placeholder "Filter events"
        , value model.filterString
        , on "input" targetValue (Signal.message address << EventList.Update.FilterEvents)
        ]
        []
    ]


viewListEvents : List Event -> Signal.Address Action -> Model -> Html
viewListEvents events address model =
  let
    filteredEvents =
      filterEventsByString events model.filterString

    hrefVoid =
      href "javascript:void(0);"

    eventSelect event =
      li []
        [ a [ hrefVoid , onClick address (EventList.Update.SelectEvent <| Just event.id) ] [ text event.label ] ]

    eventUnselect event =
      li []
        [ span []
          [ a
            [ class "unselect fa fa-times-circle"
            , href "javascript:void(0);"
            , onClick address (EventList.Update.UnSelectEvent)
            ] []
          , text event.label
          ]
        ]

    getListItem : Event -> Html
    getListItem event =
      case model.selectedEvent of
        Just id ->
          if event.id == id
            then eventUnselect(event)
            else eventSelect(event)

        Nothing ->
          eventSelect(event)
  in
    if List.isEmpty filteredEvents
      then
        div [] [ text "No results found" ]
      else
        ul [ class "authors" ] (List.map getListItem filteredEvents)
