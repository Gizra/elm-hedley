module EventCompanyFilter.Decoder where

import EventCompanyFilter.Model as EventCompanyFilter exposing (initialModel, Model)


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

decode : Json.Decoder (List Event)
decode =
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
