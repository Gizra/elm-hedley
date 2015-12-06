module ArticleForm.Update where

import ArticleForm.Model exposing (initialArticleForm, initialModel, Article, Model, UserMessage)

import Config exposing (cacheTtl)
import ConfigType exposing (BackendConfig)
import Effects exposing (Effects)
import Http exposing (post, Error)
import Json.Decode as JD exposing ((:=))
import Json.Encode as JE exposing (string)
import String exposing (toInt, toFloat)
import Task  exposing (andThen, Task)
import TaskTutorial exposing (getCurrentTime)
import Time exposing (Time)
import Utils.Http exposing (getErrorMessageFromHttpResponse)

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )

type Action
  = Activate
  | GetData
  | GetDataFromServer
  | NoOp
  | SetUserMessage UserMessage
  | UpdateDataFromServer (Result Http.Error (List Article)) Time.Time
  | UpdatePostArticle (Result Http.Error Article)

  | ResetForm
  | SubmitForm
  | SetImageId (Maybe Int)
  | UpdateBody String
  | UpdateLabel String



type alias UpdateContext =
  { accessToken : String
  , backendConfig : BackendConfig
  }

update : UpdateContext -> Action -> Model -> (Model, Effects Action)
update context action model =
  case action of
    Activate ->
      ( model
      , Task.succeed GetData |> Effects.task
      )

    GetData ->
      let
        effects =
          case model.status of
            ArticleForm.Model.Fetching ->
              Effects.none

            _ ->
              getDataFromCache model.status
      in
        ( model
        , effects
        )


    GetDataFromServer ->
      let
        backendUrl =
          (.backendConfig >> .backendUrl) context

        url =
          backendUrl ++ "/api/v1.0/articles"
      in
        ( { model | status <- ArticleForm.Model.Fetching }
        , getJson url context.accessToken
        )

    UpdatePostArticle result ->
      case result of
        Ok val ->
          -- Append the new article to the articles list.
          ( { model
            | articles <- val :: model.articles
            , postStatus <- ArticleForm.Model.Done
            }
          -- We can reset the form, as it was posted successfully.
          , Task.succeed ResetForm |> Effects.task
          )

        Err err ->
          ( { model | status <- ArticleForm.Model.HttpError err }
          , Task.succeed (SetUserMessage <| ArticleForm.Model.Error (getErrorMessageFromHttpResponse err)) |> Effects.task
          )


    SetUserMessage userMessage ->
      ( { model | userMessage <- userMessage }
      , Effects.none
      )

    UpdateDataFromServer result timestamp' ->
      case result of
        Ok articles ->
          ( { model
            | articles <- articles
            , status <- ArticleForm.Model.Fetched timestamp'
            }
          , Effects.none
          )

        Err err ->
          ( { model | status <- ArticleForm.Model.HttpError err }
          , Task.succeed (SetUserMessage <| ArticleForm.Model.Error (getErrorMessageFromHttpResponse err)) |> Effects.task
          )

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
        , postStatus <- ArticleForm.Model.Ready
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
        if model.postStatus == ArticleForm.Model.Ready
          then
            ( { model | postStatus <- ArticleForm.Model.Busy }
            , postArticle url context.accessToken model.articleForm
            )

          else
            (model, Effects.none)

    NoOp ->
      (model, Effects.none)

-- EFFECTS

getDataFromCache : ArticleForm.Model.Status -> Effects Action
getDataFromCache status =
  let
    actionTask =
      case status of
        ArticleForm.Model.Fetched fetchTime ->
          Task.map (\currentTime ->
            if fetchTime + Config.cacheTtl > currentTime
              then NoOp
              else GetDataFromServer
          ) getCurrentTime

        _ ->
          Task.succeed GetDataFromServer

  in
    Effects.task actionTask


getJson : String -> String -> Effects Action
getJson url accessToken =
  let
    params =
      [ ("access_token", accessToken)
      , ("sort", "-id")
      ]

    encodedUrl = Http.url url params

    httpTask =
      Task.toResult <|
        Http.get decodeData encodedUrl

    actionTask =
      httpTask `andThen` (\result ->
        Task.map (\timestamp' ->
          UpdateDataFromServer result timestamp'
        ) getCurrentTime
      )

  in
    Effects.task actionTask


decodeData : JD.Decoder (List Article)
decodeData =
  JD.at ["data"] <| JD.list <| decodeArticle


postArticle : String -> String -> ArticleForm.Model.ArticleForm -> Effects Action
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


dataToJson : ArticleForm.Model.ArticleForm -> String
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

decodePostArticle : JD.Decoder Article
decodePostArticle =
  JD.at ["data", "0"] <| decodeArticle


decodeArticle : JD.Decoder Article
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
      JD.object2 ArticleForm.Model.Author
        ("id" := number)
        ("label" := JD.string)

    decodeImage =
      JD.at ["styles"]
        ("thumbnail" := JD.string)

  in
    JD.object5 Article
      ("user" := decodeAuthor)
      (JD.oneOf [ "body" := JD.string, JD.succeed "" ])
      ("id" := number)
      (JD.maybe ("image" := decodeImage))
      ("label" := JD.string)
