module Event where

import Config exposing (backendUrl)
import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, targetValue)
import Http
import Json.Decode as Json exposing ((:=))
import Leaflet exposing (Model, initialModel, Marker, update)
import String exposing (length)
import Task
import Dict exposing (Dict)

import Debug

-- MODEL

type alias Id = Int

type Status =
  Init
  | Fetching
  -- @todo: Pass timestamp for "Fetched".
  | Fetched
  | HttpError Http.Error

type alias Marker =
  { lat: Float
  , lng : Float
  }

type alias Author =
  { id : Id
  , name : String
  }

type alias Event =
  { id : Id
  , label : String
  , marker : Marker
  , author : Author
  }

type alias Model =
  { events : List Event
  , status : Status
  , selectedEvent : Maybe Int
  , selectedAuthor : Maybe Int
  -- @todo: Make (Maybe String)
  , filterString : String
  , leaflet : Leaflet.Model
  }

initialModel : Model
initialModel =
  { events = []
  , status = Init
  , selectedEvent = Nothing
  , selectedAuthor = Nothing
  , filterString = ""
  , leaflet = Leaflet.initialModel
  }

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )


-- UPDATE

type Action
  = GetDataFromServer
  | UpdateDataFromServer (Result Http.Error (List Event))
  
  -- Select event might get values from JS (i.e. selecting a leaflet marker)
  -- so we allow passing a Maybe Int, instead of just Int.
  | SelectEvent (Maybe Int)
  | UnSelectEvent
  | SelectAuthor Int
  | UnSelectAuthor
  -- @todo: Make (Maybe String)
  | FilterEvents String

  -- Child actions
  | ChildLeafletAction Leaflet.Action


type alias Context =
  { accessToken : String }

update : Context -> Action -> Model -> (Model, Effects Action)
update context action model =
  case action of
    GetDataFromServer ->
      let
        url : String
        url = Config.backendUrl ++ "/api/v1.0/events"
      in
        ( { model | status <- Fetching}
        , getJson url context.accessToken
        )

    UpdateDataFromServer result ->
      case result of
        Ok events ->
          ( {model
              | events <- events
              , status <- Fetched
            }
          , Task.succeed (FilterEvents model.filterString) |> Effects.task
          )
        Err msg ->
          ( {model | status <- HttpError msg}
          , Effects.none
          )

    SelectEvent val ->
      case val of
        Just id ->
          ( { model | selectedEvent <- Just id }
          , Task.succeed (ChildLeafletAction <| Leaflet.SelectMarker <| Just id) |> Effects.task
          )
        Nothing ->
          (model, Task.succeed  UnSelectEvent |> Effects.task)

    UnSelectEvent ->
      ( { model | selectedEvent <- Nothing }
      , Task.succeed (ChildLeafletAction <| Leaflet.SelectMarker Nothing) |> Effects.task
      )

    SelectAuthor id ->
      ( { model | selectedAuthor <- Just id }
      , Effects.batch
        [ Task.succeed UnSelectEvent |> Effects.task
        , Task.succeed (FilterEvents model.filterString) |> Effects.task
        ]
      )

    UnSelectAuthor ->
      ( { model | selectedAuthor <- Nothing }
      , Effects.batch
        [ Task.succeed UnSelectEvent |> Effects.task
        , Task.succeed (FilterEvents model.filterString) |> Effects.task
        ]
      )

    FilterEvents val ->
      let
        model' = { model | filterString <- val }

        leaflet = model.leaflet
        leaflet' = { leaflet | markers <- (leafletMarkers model')}

        effects =
          case model.selectedEvent of
            Just id ->
              -- Determine if the selected event is visible (i.e. not filtered
              -- out).
              let
                isSelectedEvent =
                  filterListEvents model'
                    |> List.filter (\event -> event.id == id)
                    |> List.length
              in
                if isSelectedEvent > 0 then Effects.none else Task.succeed UnSelectEvent |> Effects.task

            Nothing ->
              Effects.none
      in
        ( { model
          | filterString <- val
          , leaflet <- leaflet'
          }
        , effects
        )

    ChildLeafletAction act ->
      let
        (childModel, childEffects) = Leaflet.update act model.leaflet
      in
        ( {model | leaflet <- childModel }
        , Effects.map ChildLeafletAction childEffects
        )

-- Build the Leaflet's markers data from the events
leafletMarkers : Model -> List Leaflet.Marker
leafletMarkers model =
  filterListEvents model
    |> List.map (\event -> Leaflet.Marker event.id event.marker.lat event.marker.lng)

-- VIEW

(=>) = (,)

view : Signal.Address Action -> Model -> Html
view address model =
  let
    message =
      Signal.send address GetDataFromServer
  in
  div []
    [ div [style [("display", "flex")]]
      [ div []
          [ div [class "h2"] [ text "Event Authors:"]
          , ul [] (viewEventsByAuthors address model.events model.selectedAuthor)
          ]
      , div []
          [ div [class "h2"] [ text "Event list:"]
          , (viewFilterString address model)
          , (viewListEvents address model)
          ]

      , div []
          [ div [class "h2"] [ text "Map:"]
          , div [ style myStyle, id "map" ] []
          , viewEventInfo model
          ]
      ]
    ]

myStyle : List (String, String)
myStyle =
    [ ("width", "600px")
    , ("height", "400px")
    ]

groupEventsByAuthors : List Event -> Dict Int (Author, Int)
groupEventsByAuthors events =
  let
    -- handleEvent : Event -> Dict Int (Author, Int) -> Dict Int (Author, Int)
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
          a [ href "#", onClick address (SelectAuthor author.id) ] [ authorRaw ]

        authorUnselect =
          span []
            [ a [ href "#", onClick address (UnSelectAuthor) ] [ text "x " ]
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

    eventSelect event =
      li []
        [ a [ href "#", onClick address (SelectEvent <| Just event.id) ] [ text event.label ] ]

    eventUnselect event =
      li []
        [ span []
          [ a [ href "#", onClick address (UnSelectEvent) ] [ text "x " ]
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
    if List.length filteredEvents > 0
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



-- EFFECTS


getJson : String -> String -> Effects Action
getJson url accessToken =
  let
    encodedUrl = Http.url url [ ("access_token", accessToken) ]
  in
    Http.send Http.defaultSettings
      { verb = "GET"
      , headers = []
      , url = encodedUrl
      , body = Http.empty
      }
      |> Http.fromJson decodeData
      |> Task.toResult
      |> Task.map UpdateDataFromServer
      |> Effects.task


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
