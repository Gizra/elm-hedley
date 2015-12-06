module Article.View where

import Article.Model exposing (Model)
import Article.Update exposing (Action)

import Html exposing (i, button, div, label, h2, h3, input, img, li, text, textarea, span, ul, Html)
import Html.Attributes exposing (action, class, id, disabled, name, placeholder, property, required, size, src, style, type', value)
import Html.Events exposing (on, onClick, onSubmit, targetValue)
import String exposing (toInt, toFloat)


view :Signal.Address Action -> Model -> Html
view address model =
  div
    [ id "article-page"
    , class "container"
    ]
    [ div
        [ class "wrapper -suffix"]
        [ viewUserMessage model.userMessage
        , viewForm address model
        ]
        , div [ class "wrapper -suffix" ] [ viewRecentArticles model.articles ]
    ]

viewUserMessage : UserMessage -> Html
viewUserMessage userMessage =
  case userMessage of
    None ->
      div [] []
    Error message ->
      div [ style [("text-align", "center")] ] [ text message ]

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
    , div [ property "innerHTML" <| JE.string article.body ] []
    , image
    ]


viewRecentArticles : List Article -> Html
viewRecentArticles articles =
  div
    []
    [ h3
        [ class "title" ]
        [ i [ class "fa fa-file-o icon" ] []
        , text "Recent articles"
        ]
    , ul [ class "articles" ] (List.map viewArticles articles)
    ]


viewForm :Signal.Address Action -> Model -> Html
viewForm address model =
  Html.form
    [ onSubmit address SubmitForm
    , action "javascript:void(0);"
    ]
    [ h3
      [ class "title" ]
      [ i [ class "fa fa-pencil" ] []
      , text " Add new article"
      ]
    -- Label
    , div
      [ class "input-group" ]
      [ label [] [ text "Label" ]
      , input
        [ type' "text"
        , class "form-control"
        , value model.articleForm.label
        , on "input" targetValue (Signal.message address << UpdateLabel)
        , required True
        ]
        []
      ]
    -- End label

    -- Body
    , div
        [ class "input-group" ]
        [ label [] [ text "Body"]
        , textarea
            [ class "form-control"
            , name "body"
            , placeholder "Body"
            , value model.articleForm.body
            , on "input" targetValue (Signal.message address << UpdateBody)
            ]
            []
        ] -- End body

        -- File upload
        , div
            [ class "input-group " ]
            [ label [] [ text "Upload File" ]
            , div [ class "dropzone" ] []
            ]

        -- Submit button
        , button
            [ onClick address SubmitForm
            , class "btn btn-lg btn-primary"
            , disabled (String.isEmpty model.articleForm.label)
            ]
            [ text "Submit" ] -- End submit button
     ]
