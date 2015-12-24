module EventAuthorFilter.Update where

import EventAuthorFilter.Model as EventAuthorFilter exposing (initialModel, Model)

init : EventAuthorFilter.Model
init = initialModel

type Action
  = SelectAuthor Int
  | UnSelectAuthor

update : Action -> Model -> Model
update action model =
  case action of
    SelectAuthor id ->
      Just id

    UnSelectAuthor ->
      Nothing
