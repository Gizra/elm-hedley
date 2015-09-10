module Company where

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

type alias Model =
  { id : Id
  , label : String
  }

initialModel : Model
initialModel =
  Model 0 ""
