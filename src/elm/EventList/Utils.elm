module EventList.Utils (filterEventsByString) where

import Event.Model exposing (Event)
import String exposing (isEmpty, trim, toLower)

filterEventsByString : List Event -> String -> List Event
filterEventsByString events filterString =
  let
    filterString' =
      String.trim filterString
  in
  if String.isEmpty filterString'
    then
      -- Return all the events.
      events

    else
      -- Filter out the events that do not contain the string.
      List.filter (\event -> String.contains (String.toLower filterString') (String.toLower event.label)) events
