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
  , mountStatus : MountStatus
  , selectedMarker : Maybe Int
  , showMap : Bool
  }

initialModel : Model
initialModel =
  { markers = []
  , mountStatus = Init
  , selectedMarker = Nothing
  , showMap = False
  }
