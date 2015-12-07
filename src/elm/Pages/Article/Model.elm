module Pages.Article.Model where

import ArticleForm.Model as ArticleForm exposing (initialModel, Model)
import ArticleList.Model as ArticleList exposing (initialModel, Model)

type alias Model =
  { articleForm : ArticleForm.Model
  , articleList : ArticleList.Model
  }

initialModel : Model
initialModel =
  { articleForm = ArticleForm.initialModel
  , articleList = ArticleList.initialModel
  }
