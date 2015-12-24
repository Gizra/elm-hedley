module Pages.Event.Utils where

import EventAuthorFilter.Model as EventAuthorFilter exposing (Model)
import Event.Model exposing (Event)

filterEventsByAuthor : List Event -> EventAuthorFilter.Model -> List Event
filterEventsByAuthor events authorFilter =
  case authorFilter of
    Just id ->
      List.filter (\event -> event.author.id == id) events

    Nothing ->
      events
