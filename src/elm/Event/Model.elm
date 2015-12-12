module Event.Model where

type alias Id = Int

type alias Marker =
  { lat: Float
  , lng : Float
  }

type alias Author =
  { id : Id
  , name : String
  }

type alias Event =
  { id : Id
  , label : String
  , marker : Marker
  , author : Author
  }
