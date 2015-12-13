module Leaflet.Model where

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
  , showMap = False
  }
