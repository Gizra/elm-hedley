module ArticleForm.View where


import ArticleForm.Model exposing (initialModel, Model, UserMessage)
import ArticleForm.Update exposing (Action)

import Html exposing (i, button, div, label, h2, h3, input, img, li, text, textarea, span, ul, Html)
import Html.Attributes exposing (action, class, id, disabled, name, placeholder, property, required, size, src, style, type', value)
import Html.Events exposing (on, onClick, onSubmit, targetValue)
import Json.Encode as JE exposing (string)
import String exposing (toInt, toFloat)


-- VIEW

view :Signal.Address Action -> Model -> Html
view address model =
  div [] [ text "Article Form" ]
