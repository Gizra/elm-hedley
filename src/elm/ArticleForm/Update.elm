module ArticleForm.Update where

import Article.Model as Article exposing (Author, Model)
import ArticleForm.Model as ArticleForm exposing (initialArticleForm, initialModel, ArticleForm, Model, UserMessage)

import ConfigType exposing (BackendConfig)
import Effects exposing (Effects)
import Http exposing (post, Error)
import Json.Decode as JD exposing ((:=))
import Json.Encode as JE exposing (string)
import String exposing (toInt, toFloat)
import Task  exposing (andThen, Task)

init : (ArticleForm.Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )

type Action
  = ResetForm
  | SubmitForm
  | SetImageId (Maybe Int)
  | UpdateBody String
  | UpdateLabel String
  | UpdatePostArticle (Result Http.Error Article.Model)



type alias UpdateContext =
  { accessToken : String
  , backendConfig : BackendConfig
  }

update : UpdateContext -> Action -> ArticleForm.Model -> (ArticleForm.Model, Effects Action)
update context action model =
  case action of
    -- @todo: Create a helper function.
    UpdateBody val ->
      let
        articleForm =
          model.articleForm

        articleForm' =
          { articleForm | body <- val }
      in
        ( { model | articleForm <- articleForm' }
        , Effects.none
        )

    UpdateLabel val ->
      let
        articleForm =
          model.articleForm

        articleForm' =
          { articleForm | label <- val }
      in
        ( { model | articleForm <- articleForm' }
        , Effects.none
        )

    SetImageId maybeVal ->
      let
        articleForm =
          model.articleForm

        articleForm' =
          { articleForm | image <- maybeVal }
      in
        ( { model | articleForm <- articleForm' }
        , Effects.none
        )

    ResetForm ->
      ( { model
        | articleForm <- initialArticleForm
        , postStatus <- ArticleForm.Ready
        }
      , Effects.none
      )

    SubmitForm ->
      let
        backendUrl =
          (.backendConfig >> .backendUrl) context

        url =
          backendUrl ++ "/api/v1.0/articles"
      in
        if model.postStatus == ArticleForm.Ready
          then
            ( { model | postStatus <- ArticleForm.Busy }
            , postArticle url context.accessToken model.articleForm
            )

          else
            (model, Effects.none)


-- EFFECTS

postArticle : String -> String -> ArticleForm.ArticleForm -> Effects Action
postArticle url accessToken data =
  let
    params =
      [ ("access_token", accessToken) ]

    encodedUrl =
      Http.url url params
  in
    Http.post
      decodePostArticle
      encodedUrl
      (Http.string <| dataToJson data )
      |> Task.toResult
      |> Task.map UpdatePostArticle
      |> Effects.task


dataToJson : ArticleForm.ArticleForm -> String
dataToJson data =
  let
    intOrNull maybeVal =
      case maybeVal of
        Just val -> JE.int val
        Nothing -> JE.null
  in
    JE.encode 0
      <| JE.object
          [ ("label", JE.string data.label)
          , ("body", JE.string data.body)
          , ("image", intOrNull data.image)
          ]

decodePostArticle : JD.Decoder Article.Model
decodePostArticle =
  JD.at ["data", "0"] <| decodeArticle


decodeArticle : JD.Decoder Article.Model
decodeArticle =
  let
    -- Cast String to Int.
    number : JD.Decoder Int
    number =
      JD.oneOf [ JD.int, JD.customDecoder JD.string String.toInt ]


    numberFloat : JD.Decoder Float
    numberFloat =
      JD.oneOf [ JD.float, JD.customDecoder JD.string String.toFloat ]

    decodeAuthor =
      JD.object2 Article.Author
        ("id" := number)
        ("label" := JD.string)

    decodeImage =
      JD.at ["styles"]
        ("thumbnail" := JD.string)

  in
    JD.object5 Article.Model
      ("user" := decodeAuthor)
      (JD.oneOf [ "body" := JD.string, JD.succeed "" ])
      ("id" := number)
      (JD.maybe ("image" := decodeImage))
      ("label" := JD.string)
