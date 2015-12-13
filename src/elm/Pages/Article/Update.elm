module Pages.Article.Update where

import ArticleForm.Update exposing (Action)
import ArticleList.Update exposing (Action)
import Config.Model exposing (BackendConfig)
import Effects exposing (Effects)
import Pages.Article.Model exposing (Model)
import Task exposing (succeed)

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
        ( model
        , Task.succeed (ChildArticleListAction ArticleList.Update.GetData) |> Effects.task
        )

    ChildArticleFormAction act ->
      let
        (childModel, childEffects, maybeArticle) = ArticleForm.Update.update context act model.articleForm

        defaultEffects =
          [ Effects.map ChildArticleFormAction childEffects ]

        effects' =
          case maybeArticle of
            Just article ->
              (Task.succeed (ChildArticleListAction <| ArticleList.Update.AppendArticle article) |> Effects.task)
              ::
              defaultEffects
            Nothing ->
              defaultEffects

      in

        ( { model | articleForm = childModel }
        , Effects.batch effects'
        )

    ChildArticleListAction act ->
      let
        (childModel, childEffects) = ArticleList.Update.update context act model.articleList
      in
        ( { model | articleList = childModel }
        , Effects.map ChildArticleListAction childEffects
        )
