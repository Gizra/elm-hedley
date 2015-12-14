module EventAuthorFilter.Update where

import EventAuthorFilter.Model as EventAuthorFilter exposing (initialModel, Model)

import Effects exposing (Effects)

init : (EventAuthorFilter.Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )


type Action
  = SelectAuthor Int
  | UnSelectAuthor

type alias Model = EventAuthorFilter.Model

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    SelectAuthor id ->
      ( Just id
      , Effects.none
      )

    UnSelectAuthor ->
      ( Nothing
      , Effects.none
      )
