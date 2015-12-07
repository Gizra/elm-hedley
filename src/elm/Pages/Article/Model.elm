module Pages.Article.Model where

import ArticleForm.Model as ArticleForm exposing (initialModel, Model)
import ArticleList.Model as ArticleList exposing (initialModel, Model)

type alias Ports =
  { dropzoneUploadedFile: Maybe Int
  , ckeditor : String
  }

type alias Model =
  { articleForm : ArticleForm.Model
  , articleList : ArticleList.Model
  , ports : Ports
  }

initialPorts : Ports
initialPorts =
  { dropzoneUploadedFile = Nothing
  , ckeditor = ""
  }

initialModel : Model
initialModel =
  { articleForm = ArticleForm.initialModel
  , articleList = ArticleList.initialModel
  , ports = initialPorts
  }
