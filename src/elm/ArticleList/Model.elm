module ArticleList.Model where

import Article.Model as Article exposing (Model)
import Http exposing (Error)
import Time exposing (Time)

type alias Id = Int

type Status =
  Init
  | Fetching
  | Fetched Time.Time
  | HttpError Http.Error


type alias Model =
  { articles : List Article.Model
  , status : Status
  }

initialModel : Model
initialModel =
  { articles = []
  , status = Init
  }
