module Pages.Article.View where

import ArticleForm.View as ArticleForm exposing (view)
import ArticleList.View as ArticleList exposing (view)
import Html exposing (i, button, div, label, h2, h3, input, img, li, text, textarea, span, ul, Html)
import Html.Attributes exposing (action, class, id, disabled, name, placeholder, property, required, size, src, style, type', value)
import Pages.Article.Model as Article exposing (Model)
import Pages.Article.Update exposing (Action)


view : Signal.Address Action -> Article.Model -> Html
view address model =
  let
    childArticleFormAddress =
      Signal.forwardTo address Pages.Article.Update.ChildArticleFormAction

    childArticleListAddress =
      Signal.forwardTo address Pages.Article.Update.ChildArticleListAction
  in
    div
      [ id "article-page"
      , class "container"
      ]
      [ ArticleForm.view childArticleFormAddress model.articleForm
      , ArticleList.view childArticleListAddress model.articleList
      ]
