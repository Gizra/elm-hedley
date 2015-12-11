module EventCompanyFilter.View where

import EventCompanyFilter.Model as EventCompanyFilter exposing (initialModel, Model)
import EventCompanyFilter.Update exposing (Action)

-- import Config exposing (cacheTtl)
-- import ConfigType exposing (BackendConfig)
import Company.Model as Company exposing (Model)
-- import Dict exposing (Dict)
-- import Effects exposing (Effects)
-- import Html exposing (a, div, input, text, select, span, li, option, ul, Html)
-- import Html.Attributes exposing (class, hidden, href, id, placeholder, selected, style, value)
-- import Html.Events exposing (on, onClick, targetValue)
-- import Http
-- import Json.Decode as Json exposing ((:=))
-- import Leaflet exposing (Model, initialModel, Marker, update)
-- import RouteHash exposing (HashUpdate)
-- import String exposing (length)
-- import Task  exposing (andThen, Task)
-- import TaskTutorial exposing (getCurrentTime)
-- import Time exposing (Time)

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
      , on "change" targetValue (\str -> Signal.message address <| SelectCompany <| textToMaybe str)
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
          a [ href "javascript:void(0);", onClick address (SelectAuthor author.id) ] [ authorRaw ]

        authorUnselect =
          span []
            [ a [ href "javascript:void(0);", onClick address (UnSelectAuthor) ] [ text "x " ]
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
        , on "input" targetValue (Signal.message address << FilterEvents)
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
        [ a [ hrefVoid , onClick address (SelectEvent <| Just event.id) ] [ text event.label ] ]

    eventUnselect event =
      li []
        [ span []
          [ a [ href "javascript:void(0);", onClick address (UnSelectEvent) ] [ text "x " ]
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

isFetched : Status -> Bool
isFetched status =
  case status of
    Fetched _ _ -> True
    _ -> False

-- EFFECTS

getDataFromCache : Status -> Maybe CompanyId -> Effects Action
getDataFromCache status maybeCompanyId =
  let
    getFx =
      Task.succeed <| GetDataFromServer maybeCompanyId

    actionTask =
      case status of
        Fetched id fetchTime ->
          if id == maybeCompanyId
            then
              Task.map (\currentTime ->
                if fetchTime + Config.cacheTtl > currentTime
                  then NoOp
                  else GetDataFromServer maybeCompanyId
              ) getCurrentTime
            else
              getFx

        _ ->
          getFx

  in
    Effects.task actionTask


getJson : String -> Maybe CompanyId -> String -> Effects Action
getJson url maybeCompanyId accessToken =
  let
    params =
      [ ("access_token", accessToken) ]

    params' =
      case maybeCompanyId of
        Just id ->
          -- Filter by company
          ("filter[company]", toString id) :: params

        Nothing ->
          params


    encodedUrl =
      Http.url url params'

    httpTask =
      Task.toResult <|
        Http.get decodeData encodedUrl

    actionTask =
      httpTask `andThen` (\result ->
        Task.map (\timestamp ->
          UpdateDataFromServer result maybeCompanyId timestamp
        ) getCurrentTime
      )

  in
    Effects.task actionTask


decodeData : Json.Decoder (List Event)
decodeData =
  let
    -- Cast String to Int.
    number : Json.Decoder Int
    number =
      Json.oneOf [ Json.int, Json.customDecoder Json.string String.toInt ]


    numberFloat : Json.Decoder Float
    numberFloat =
      Json.oneOf [ Json.float, Json.customDecoder Json.string String.toFloat ]

    marker =
      Json.object2 Marker
        ("lat" := numberFloat)
        ("lng" := numberFloat)

    author =
      Json.object2 Author
        ("id" := number)
        ("label" := Json.string)
  in
    Json.at ["data"]
      <| Json.list
      <| Json.object4 Event
        ("id" := number)
        ("label" := Json.string)
        ("location" := marker)
        ("user" := author)

-- ROUTER

delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
  let
    url =
      case current.selectedCompany of
        Just companyId -> [ toString (companyId) ]
        Nothing -> []
  in
    Just <| RouteHash.set url

location2company : List String -> Maybe Int
location2company list =
  case List.head list of
    Just eventId ->
      case String.toInt eventId of
        Ok val ->
          Just val
        Err _ ->
          Nothing

    Nothing ->
      Nothing
