module Article.Update where

import Article.Model exposing (Model)

import ArticleForm.Update exposing (Action)
import ArticleList.Update exposing (Action)

-- import Config exposing (cacheTtl)
import ConfigType exposing (BackendConfig)
-- import Effects exposing (Effects)
-- import Html exposing (i, button, div, label, h2, h3, input, img, li, text, textarea, span, ul, Html)
-- import Html.Attributes exposing (action, class, id, disabled, name, placeholder, property, required, size, src, style, type', value)
-- import Html.Events exposing (on, onClick, onSubmit, targetValue)
-- import Http exposing (post)
-- import Json.Decode as JD exposing ((:=))
-- import Json.Encode as JE exposing (string)
-- import String exposing (toInt, toFloat)
-- import Task  exposing (andThen, Task)
-- import TaskTutorial exposing (getCurrentTime)
-- import Time exposing (Time)
-- import Utils.Http exposing (getErrorMessageFromHttpResponse)


type Action
  = Activate
  | ChildArticleFormAction ArticleForm.Update.Action
  | ChildArticleListAction ArticleList.Update.Action

type alias UpdateContext =
  { accessToken : String
  , backendConfig : BackendConfig
  }

update : UpdateContext -> Action -> Model -> (Model, Effects Action)
update context action model =
  case action of
    Activate ->
      let
        (childModel, childEffects) = ArticleList.update context ArticleList.GetData model.articleList
      in
        ( {model | articleList <- childModel }
        , Effects.map ChildArticleListAction childEffects
        )
