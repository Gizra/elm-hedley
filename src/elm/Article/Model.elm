module Article.Model where

type alias Id = Int

type alias Model =
  { author : Author
  , body : String
  , id : Id
  , image : Maybe String
  , label : String
  }

type alias Author =
  { id : Id
  , name : String
  }
