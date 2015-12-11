module Company.Model where

type alias Id = Int

type alias Model =
  { id : Id
  , label : String
  }

initialModel : Model
initialModel =
  Model 0 ""
