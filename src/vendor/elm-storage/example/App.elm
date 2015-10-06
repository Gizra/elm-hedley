module App where

import Effects exposing (Effects)
import Json.Encode as JE exposing (string, Value)
import Json.Decode as JD
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, targetValue)
import Storage exposing (..)
import Task exposing (..)

import Debug

type alias Model = Maybe String

initialModel : Model
initialModel =
  Nothing

init : (Model, Effects Action)
init =
  ( initialModel
  , getInputFromStorage
  )

-- UPDATE

type Action
  = GetStorage (Result String ())
  | SetStorage String
  | UpdateModel (Result String String)


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    GetStorage result ->
      case result of
        Ok s ->
          (model, getInputFromStorage)
        Err err ->
          (model, Effects.none)


    SetStorage s ->
      -- Don't update the model here, instead after this action is done, the
      -- effect should call another action to update the model.
      (model, sendInputToStorage s)

    UpdateModel result ->
      case result of
        Ok s ->
          (Just s, Effects.none)
        Err err ->
          (model, Effects.none)


sendInputToStorage : String -> Effects Action
sendInputToStorage s =
  Storage.setItem "Test" (JE.string s)
    |> Task.toResult
    |> Task.map GetStorage
    |> Effects.task

getInputFromStorage : Effects Action
getInputFromStorage =
  getItem "Test" JD.string
    |> Task.toResult
    |> Task.map UpdateModel
    |> Effects.task

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  let
    existingValue =
      case model of
        Just s ->
          text s
        Nothing ->
          text ""
  in
  div []
  [ h2 [] [ text "Storage example"]
  , input
      [ on "input" targetValue (Signal.message address << SetStorage)
      , required True
      , placeholder "Add some text"
      ] []
  , existingValue
  ]
