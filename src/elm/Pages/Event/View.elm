module Pages.Event.View where

import Company.Model as Company exposing (Model)
import Event.Model exposing (Author, Event)
import EventAuthorFilter.View exposing (view)
import EventCompanyFilter.View exposing (view)
import Html exposing (a, div, input, text, select, span, li, option, ul, Html)
import Html.Attributes exposing (class, hidden, href, id, placeholder, selected, style, value)
import Html.Events exposing (on, onClick, targetValue)
import Pages.Event.Model exposing (initialModel, Model)
import Pages.Event.Update exposing (Action)
import String exposing (length)

type alias Action = Pages.Event.Update.Action
type alias CompanyId = Int
type alias Model = Pages.Event.Model.Model

type alias Context =
  { companies : List Company.Model }

view : Context -> Signal.Address Action -> Model -> Html
view context address model =
  let

    childEventAuthorFilterAddress =
      Signal.forwardTo address Pages.Event.Update.ChildEventAuthorFilterAction

    childEventCompanyFilterAddress =
      Signal.forwardTo address Pages.Event.Update.ChildEventCompanyFilterAction
  in
    div [class "container"]
      [ div [class "row"]
        [ div [class "col-md-3"]
            [ (EventCompanyFilter.View.view context.companies childEventCompanyFilterAddress model.selectedCompany)
            -- , (EventAuthorFilter.View.view model.events childEventAuthorFilterAddress model.selectedAuthor)

            , div []
                [ div [class "h2"] [ text "Event list"]
                , (viewFilterString address model)
                , (viewListEvents address model)
                ]
            ]

        , div [class "col-md-9"]
            [ div [class "h2"] [ text "Map"]
            , div [ style mapStyle, id "map" ] []
            , viewEventInfo model
            ]
        ]
      ]


mapStyle : List (String, String)
mapStyle =
  [ ("width", "600px")
  , ("height", "400px")
  ]


-- In case an author or string-filter is selected, filter the events.
filterListEvents : Model -> List Event
filterListEvents model =
  let
    authorFilter : List Event -> List Event
    authorFilter events =
      case model.selectedAuthor of
        Just id ->
          List.filter (\event -> event.author.id == id) events

        Nothing ->
          events

    stringFilter : List Event -> List Event
    stringFilter events =
      if String.length (String.trim model.filterString) > 0
        then
          List.filter (\event -> String.contains (String.trim (String.toLower model.filterString)) (String.toLower event.label)) events

        else
          events

  in
    authorFilter model.events
     |> stringFilter

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




viewEventInfo : Model -> Html
viewEventInfo model =
  case model.selectedEvent of
    Just val ->
      let
        -- Get the selected event.
        selectedEvent = List.filter (\event -> event.id == val) model.events

      in
        div [] (List.map (\event -> text (toString(event.id) ++ ") " ++ event.label ++ " by " ++ event.author.name)) selectedEvent)

    Nothing ->
      div [] []

isFetched : Pages.Event.Model.Status -> Bool
isFetched status =
  case status of
    Pages.Event.Model.Fetched _ _ -> True
    _ -> False
