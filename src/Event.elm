module Event where

import Config exposing (backendUrl)
import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, targetValue)
import Http
import Json.Decode as Json exposing ((:=))
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
  }

initialModel : Model
initialModel =
  { events = []
  , status = Init
  , selectedEvent = Nothing
  , selectedAuthor = Nothing
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
  | SelectEvent Int
  | UnSelectEvent
  | SelectAuthor Int
  | UnSelectAuthor

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    GetDataFromServer ->
      let
        url : String
        url = Config.backendUrl ++ "/api/v1.0/events"
      in
        ( { model | status <- Fetching}
          -- @todo: Remove access token hardcoding.
        , getJson url "erUOM1tKSABIGmcCKPoXhZYxO-7F4qUBGyxjRL7oUKs"
        )

    UpdateDataFromServer result ->
      case result of
        Ok events ->
          ( {model
              | events <- events
              , status <- Fetched
            }
          , Effects.none
          )
        Err msg ->
          ( {model | status <- HttpError msg}
          , Effects.none
          )

    SelectEvent id ->
      ( { model | selectedEvent <- Just id }
      , Effects.none
      )

    UnSelectEvent ->
      ( { model | selectedEvent <- Nothing }
      , Effects.none
      )

    SelectAuthor id ->
      ( { model | selectedAuthor <- Just id }
      , Task.succeed UnSelectEvent |> Effects.task
      )

    UnSelectAuthor ->
      ( { model | selectedAuthor <- Nothing }
      , Task.succeed UnSelectEvent |> Effects.task
      )


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
          [ div [class "h2"] [ text "Event info:"]
          , ul [] (viewEventsByAuthors address model.events model.selectedAuthor)
          ]
      , div []
          [ div [class "h2"] [ text "Event list:"]
          , ul [] (viewListEvents address model.events model.selectedAuthor model.selectedEvent)
          ]

      , div []
          [ div [class "h2"] [ text "Event info:"]
          , viewEventInfo model
          ]
      ]
    , button [ onClick address GetDataFromServer ] [ text "Refresh" ]
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


-- In case an author is selected, filter the events.
filterListEvents : List Event -> Maybe Int -> List Event
filterListEvents events selectedAuthor =
  case selectedAuthor of
    Just id ->
      List.filter (\event -> event.author.id == id) events

    Nothing ->
      events


viewListEvents : Signal.Address Action -> List Event -> Maybe Int -> Maybe Int -> List Html
viewListEvents address events selectedAuthor selectedEvent  =
  let
    filteredEvents = filterListEvents events selectedAuthor

    eventSelect event =
      li []
        [ a [ href "#", onClick address (SelectEvent event.id) ] [ text event.label ] ]

    eventUnselect event =
      li []
        [ span []
          [ a [ href "#", onClick address (UnSelectEvent) ] [ text "x " ]
          , text event.label
          ]
        ]

    getListItem : Event -> Html
    getListItem event =
      case selectedEvent of
        Just id ->
          if event.id == id then eventUnselect(event) else eventSelect(event)

        Nothing ->
          eventSelect(event)
  in
    List.map getListItem filteredEvents


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
