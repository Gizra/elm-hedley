module ArticleForm.Model where

type alias Model =
  { label : String
  , body : String
  , image : Maybe Int
  , show : Bool
  }

initialModel : Model
initialModel =
  { label = ""
  , body = ""
  , image = Nothing
  , show = True
  }
