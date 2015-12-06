module ArticleList.Model where

import Http exposing (Error)
import Time exposing (Time)

type alias Id = Int

type Status =
  Init
  | Fetching
  | Fetched Time.Time
  | HttpError Http.Error


type alias Author =
  { id : Id
  , name : String
  }

type alias Article =
  { author : Author
  , body : String
  , id : Id
  , image : Maybe String
  , label : String
  }

type alias ArticleList =
  { label : String
  , body : String
  , image : Maybe Int
  , show : Bool
  }

initialArticleList : ArticleList
initialArticleList =
  { label = ""
  , body = ""
  , image = Nothing
  , show = True
  }

type alias Model =
  { articles : List Article
  , status : Status
  }

initialModel : Model
initialModel =
  { articles = []
  , status = Init
  }
