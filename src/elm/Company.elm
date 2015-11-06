module Company where

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
