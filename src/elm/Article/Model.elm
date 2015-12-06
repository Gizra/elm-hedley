module Article.Model where

import ArticleForm.Model exposing (Model)
import ArticleList.Model exposing (Model)

type alias Id = Int

type alias Article =
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

type alias Model =
  { articleForm : ArticleForm.Model.Model
  , articleList : ArticleList.Model.Model
  }
