module Article.View where

import Article.Page as Article exposing (Model)
import Article.Update exposing (Action)

import Html exposing (i, button, div, label, h2, h3, input, img, li, text, textarea, span, ul, Html)
import Html.Attributes exposing (action, class, id, disabled, name, placeholder, property, required, size, src, style, type', value)
import Html.Events exposing (on, onClick, onSubmit, targetValue)
import String exposing (toInt, toFloat)


view :Signal.Address Action -> Article.Model -> Html
view address model =
  div [] []
