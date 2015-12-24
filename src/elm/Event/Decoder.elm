module Event.Decoder where

import Event.Model as Event exposing (Author, Event, Marker)
import Json.Decode as JD exposing ((:=))
import String exposing (toInt, toFloat)

decode : JD.Decoder (List Event)
decode =
  let
    -- Cast String to Int.
    number : JD.Decoder Int
    number =
      JD.oneOf [ JD.int, JD.customDecoder JD.string String.toInt ]


    numberFloat : JD.Decoder Float
    numberFloat =
      JD.oneOf [ JD.float, JD.customDecoder JD.string String.toFloat ]

    marker =
      JD.object2 Marker
        ("lat" := numberFloat)
        ("lng" := numberFloat)

    author =
      JD.object2 Author
        ("id" := number)
        ("label" := JD.string)
  in
    JD.at ["data"]
      <| JD.list
      <| JD.object4 Event
        ("user" := author)
        ("id" := number)
        ("label" := JD.string)
        ("location" := marker)
