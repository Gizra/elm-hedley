module Article.Update where

import Article.Model exposing (Model)

import ArticleForm.Update exposing (Action)
import ArticleList.Update exposing (Action)

import ConfigType exposing (BackendConfig)

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
