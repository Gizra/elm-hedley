module EventAuthorFilter.View where

import EventAuthorFilter.Model as EventAuthorFilter exposing (initialModel, Model)
import EventAuthorFilter.Update exposing (Action)

import Dict exposing (Dict)
import Event.Model as Event exposing (Author, Event)
import Html exposing (h3, a, i, div, input, text, select, span, li, option, ul, Html)
import Html.Attributes exposing (class, hidden, href, id, placeholder, selected, style, value)
import Html.Events exposing (on, onClick, targetValue)

type alias Model = EventAuthorFilter.Model

view : List Event -> Signal.Address Action -> Model -> Html
view events address eventAuthorFilter =
  div
    [ class "wrapper -suffix" ]
    [ h3
      [ class "title" ]
      [ i [ class "glyphicon glyphicon-user" ] []
      , text <| " " ++ "Event Authors"
      ]
    , ul [ class "authors" ] (viewEventsByAuthors events address eventAuthorFilter)
    ]

viewEventsByAuthors : List Event -> Signal.Address Action -> Maybe Int -> List Html
viewEventsByAuthors events address eventAuthorFilter =
  let
    getText : Author -> Int -> Html
    getText author count =
      let
        authorRaw =
          text (author.name ++ " (" ++ toString(count) ++ ")")

        authorSelect =
          a [ href "javascript:void(0);", onClick address (EventAuthorFilter.Update.SelectAuthor author.id) ] [ authorRaw ]

        authorUnselect =
          span []
            [ a
              [ class "unselect fa fa-times-circle"
              , href "javascript:void(0);"
              , onClick address (EventAuthorFilter.Update.UnSelectAuthor)
              ] []
            , authorRaw
            ]
      in
        case eventAuthorFilter of
          Just id ->
            if author.id == id then authorUnselect else authorSelect

          Nothing ->
            authorSelect

    viewAuthor (author, count) =
      li [] [getText author count]
  in
    -- Get HTML from the grouped events
    groupEventsByAuthors events |>
      Dict.values |>
        List.map viewAuthor

groupEventsByAuthors : List Event -> Dict Int (Author, Int)
groupEventsByAuthors events =
  let
    handleEvent : Event -> Dict Int (Author, Int) -> Dict Int (Author, Int)
    handleEvent event dict =
      let
        currentValue =
          Maybe.withDefault (event.author, 0) <|
            Dict.get event.author.id dict

        newValue =
          case currentValue of
            (author, count) -> (author, count + 1)
      in
        Dict.insert event.author.id newValue dict

  in
    List.foldl handleEvent Dict.empty events
