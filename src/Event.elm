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

type alias Event =
  { id : Id
  , label : String
  , marker : Marker
  }

type alias Model =
  { events : List Event
  , status : Status
  }


initialModel : Model
initialModel =
  Model [] Init

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )


-- UPDATE

type Action
  = GetDataFromServer
  | UpdateDataFromServer (Result Http.Error (List Event))

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

-- VIEW

(=>) = (,)

view : Signal.Address Action -> Model -> Html
view address model =
  let
    message =
      Signal.send address GetDataFromServer
  in
  div []
    [ div [class "h2"] [ text "Event list:"]
    , ul [] (List.map viewListEvents model.events)
    , button [ onClick address GetDataFromServer ] [ text "Refresh" ]
    ]


viewListEvents : Event -> Html
viewListEvents event =
  li [] [text event.label]


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
  in
  Json.at ["data"]
    <| Json.list
    <| Json.object3 Event
      ("id" := number)
      ("label" := Json.string)
      ("location" := marker)
