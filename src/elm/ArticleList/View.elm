module ArticleList.View where

import Article.Model exposing (Model)

import ArticleList.Model exposing (initialModel, Model)
import ArticleList.Update exposing (Action)

import Html exposing (i, button, div, label, h2, h3, input, img, li, text, textarea, span, ul, Html)
import Html.Attributes exposing (action, class, id, disabled, name, placeholder, property, required, size, src, style, type', value)
import Html.Events exposing (on, onClick, onSubmit, targetValue)
import Json.Encode as JE exposing (string)
import String exposing (toInt, toFloat)


type alias Article = Article.Model.Model

type alias Model = ArticleList.Model.Model

view : Signal.Address Action -> Model -> Html
view address model =
  viewRecentArticles model.articles

viewRecentArticles : List Article -> Html
viewRecentArticles articles =
  div
    [ class "wrapper -suffix" ]
    [ h3
        [ class "title" ]
        [ i [ class "fa fa-file-o icon" ] []
        , text "Recent articles"
        ]
    , ul [ class "articles" ] (List.map viewArticles articles)
    ]

viewArticles : Article -> Html
viewArticles article =
  let
    image =
      case article.image of
        Just val -> img [ src val ] []
        Nothing -> div [] []
  in
    li
      []
      [ div [ class "title" ] [ text article.label ]
      -- Allow attaching HTML without escaping it. XSS is escaped in the server
      -- side.
      , div [ property "innerHTML" <| JE.string article.body ] []
      , image
      ]
