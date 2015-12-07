module Company.Model where

type alias CompanyId = Int

type alias Model =
  { id : CompanyId
  , label : String
  }

initialModel : Model
initialModel =
  { id = 0
  , label = ""
  }
