module Pages.Event.View where

import Company.Model as Company exposing (Model)
import Dict exposing (Dict)
import Event.Model exposing (Author, Event)
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
  div [class "container"]
    [ div [class "row"]
      [ div [class "col-md-3"]
          [ div []
              [ div [class "h2"] [ text "Companies"]
              , companyListForSelect address context.companies model.selectedCompany
              ]

          , div []
              [ div [class "h2"] [ text "Event Authors"]
              , ul [] (viewEventsByAuthors address model.events model.selectedAuthor)
              , div [ hidden (isFetched model.status)] [ text "Loading..."]
              ]

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

companyListForSelect : Signal.Address Action -> List Company.Model -> Maybe CompanyId -> Html
companyListForSelect address companies selectedCompany  =
  let
    selectedText =
      case selectedCompany of
        Just id ->
          toString id
        Nothing ->
          ""

    textToMaybe string =
      if string == "0"
        then Nothing
        else
          -- Converting to int return a result.
          case (String.toInt string) of
            Ok val ->
              Just val
            Err _ ->
              Nothing


    -- Add an "All companies" option
    companies' =
      (Company.Model 0 "-- All companies --") :: companies

    -- The selected company ID.
    selectedId =
      case selectedCompany of
        Just id ->
          id
        Nothing ->
          0

    getOption company =
      option [value <| toString company.id, selected (company.id == selectedId)] [ text company.label]
  in
    select
      [ value selectedText
      , on "change" targetValue (\str -> Signal.message address <| Pages.Event.Update.SelectCompany <| textToMaybe str)
      ]
      (List.map getOption companies')


mapStyle : List (String, String)
mapStyle =
  [ ("width", "600px")
  , ("height", "400px")
  ]

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

viewEventsByAuthors : Signal.Address Action -> List Event -> Maybe Int -> List Html
viewEventsByAuthors address events selectedAuthor =
  let
    getText : Author -> Int -> Html
    getText author count =
      let
        authorRaw =
          text (author.name ++ " (" ++ toString(count) ++ ")")

        authorSelect =
          a [ href "javascript:void(0);", onClick address (Pages.Event.Update.SelectAuthor author.id) ] [ authorRaw ]

        authorUnselect =
          span []
            [ a [ href "javascript:void(0);", onClick address (Pages.Event.Update.UnSelectAuthor) ] [ text "x " ]
            , authorRaw
            ]
      in
        case selectedAuthor of
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
