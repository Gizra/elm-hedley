module Leaflet.Model where

type MountStatus
  = Init
  | InProgress
  | Done

type alias Marker =
  { id : Int
  , lat : Float
  , lng : Float
  }

type alias Model =
  { markers : List Marker
  , selectedMarker : Maybe Int
  , showMap : Bool
  , mountStatus : MountStatus
  }

initialModel : Model
initialModel =
  { markers = []
  , selectedMarker = Nothing
  , showMap = False
  , mountStatus = Init
  }
