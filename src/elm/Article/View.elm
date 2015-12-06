module Article.View where

import Article.Page as Article exposing (Model)
import Article.Update exposing (Action)

import ArticleForm.View as ArticleForm exposing (view)
import ArticleList.View as ArticleList exposing (view)

import Html exposing (i, button, div, label, h2, h3, input, img, li, text, textarea, span, ul, Html)
import Html.Attributes exposing (action, class, id, disabled, name, placeholder, property, required, size, src, style, type', value)
import Html.Events exposing (on, onClick, onSubmit, targetValue)


view : Signal.Address Action -> Article.Model -> Html
view address model =
  let
    childArticleFormAddress =
      Signal.forwardTo address Article.Update.ChildArticleFormAction

    childArticleListAddress =
      Signal.forwardTo address Article.Update.ChildArticleListAction
  in
    div
      []
      [ ArticleForm.view childArticleFormAddress model.articleForm
      , ArticleList.view childArticleListAddress model.articleList
      ]
