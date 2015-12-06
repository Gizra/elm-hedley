module Article.Page where

import ArticleForm.Model as ArticleForm exposing (Model)
import ArticleList.Model as ArticleList exposing (Model)

type alias Model =
  { articleForm : ArticleForm.Model
  , articleList : ArticleList.Model
  }
