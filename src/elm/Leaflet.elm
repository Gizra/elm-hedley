module Leaflet where

import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick)
import Task exposing (map)

-- MODEL

type alias Marker =
  { id : Int
  , lat : Float
  , lng : Float
  }

type alias Model =
  { markers : List Marker
  , selectedMarker : Maybe Int
  , showMap : Bool
  }

initialModel : Model
initialModel =
  { markers = []
  , selectedMarker = Nothing
  , showMap = True
  }

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )


-- UPDATE

type Action
  = ToggleMap
  | SelectMarker (Maybe Int)
  | UnselectMarker


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    ToggleMap ->
      ( { model | showMap <- (not model.showMap) }
      , Effects.none
      )

    SelectMarker val ->
      ( { model | selectedMarker <- val }
      , Effects.none
      )

    UnselectMarker ->
      ( { model | selectedMarker <- Nothing }
      , Effects.none
      )


-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  if model.showMap
    then div [ style myStyle, id "map" ] []
    -- We use span, so the div element will be completely removed.
    else span [] []

myStyle : List (String, String)
myStyle =
    [ ("width", "600px")
    , ("height", "400px")
    ]
