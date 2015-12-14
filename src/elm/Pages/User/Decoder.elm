module Pages.User.Decoder where

import Company.Model as Company exposing (Model)
import Effects exposing (Effects, Never)
import Http exposing (Error)
import Json.Decode as Json exposing ((:=))
import String
import Task

import Pages.User.Model as User exposing (..)

decode : Json.Decoder (User.Id, String, List Company.Model)
decode =
  let
    -- Cast String to Int.
    number : Json.Decoder Int
    number =
      Json.oneOf [ Json.int, Json.customDecoder Json.string String.toInt ]

    company =
      Json.object2 Company.Model
        ("id" := number)
        ("label" := Json.string)
  in
    Json.at ["data", "0"]
      <| Json.object3 (,,)
        ("id" := number)
        ("label" := Json.string)
        ("companies" := Json.list company)
