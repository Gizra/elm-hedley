module Pages.Article.Update where

import ArticleForm.Update exposing (Action)
import ArticleList.Update exposing (Action)
import ConfigType exposing (BackendConfig)
import Effects exposing (Effects)
import Pages.Article.Model exposing (Model)

type Action
  = Activate
  | ChildArticleFormAction ArticleForm.Update.Action
  | ChildArticleListAction ArticleList.Update.Action

type alias UpdateContext =
  { accessToken : String
  , backendConfig : BackendConfig
  }

init : (Model, Effects Action)
init =
  ( Pages.Article.Model.initialModel
  , Effects.none
  )

update : UpdateContext -> Action -> Pages.Article.Model.Model -> (Pages.Article.Model.Model, Effects Action)
update context action model =
  case action of
    Activate ->
      let
        (childModel, childEffects) = ArticleList.Update.update context ArticleList.Update.GetData model.articleList
      in
        ( { model | articleList <- childModel }
        , Effects.map ChildArticleListAction childEffects
        )

    ChildArticleFormAction act ->
      let
        (childModel, childEffects) = ArticleForm.Update.update context act model.articleForm
      in
        ( { model | articleForm <- childModel }
        , Effects.map ChildArticleFormAction childEffects
        )

    ChildArticleListAction act ->
      let
        (childModel, childEffects) = ArticleList.Update.update context act model.articleList
      in
        ( { model | articleList <- childModel }
        , Effects.map ChildArticleListAction childEffects
        )
