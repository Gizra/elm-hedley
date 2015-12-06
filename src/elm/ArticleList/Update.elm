module ArticleList.Update where

import Article.Model as Article exposing (Model)
import ArticleList.Model exposing (initialModel, Model)

import Config exposing (cacheTtl)
import ConfigType exposing (BackendConfig)
import Effects exposing (Effects)
import Http exposing (post, Error)
import Json.Decode as JD exposing ((:=))
import String exposing (toInt, toFloat)
import Task  exposing (andThen, Task)
import TaskTutorial exposing (getCurrentTime)
import Time exposing (Time)

init : (ArticleList.Model.Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )

type Action
  = GetData
  | GetDataFromServer
  | NoOp
  | UpdateDataFromServer (Result Http.Error (List Article.Model)) Time.Time
  | UpdatePostArticle (Result Http.Error Article.Model)


type alias UpdateContext =
  { accessToken : String
  , backendConfig : BackendConfig
  }

update : UpdateContext -> Action -> ArticleList.Model.Model -> (ArticleList.Model.Model, Effects Action)
update context action model =
  case action of
    GetData ->
      let
        effects =
          case model.status of
            ArticleList.Model.Fetching ->
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
        ( { model | status <- ArticleList.Model.Fetching }
        , getJson url context.accessToken
        )

    UpdatePostArticle result ->
      case result of
        Ok val ->
          -- Append the new article to the articles list.
          ( { model | articles <- val :: model.articles }
          -- @todo: We can reset the form, as it was posted successfully.
          , Effects.none
          )

        Err err ->
          ( { model | status <- ArticleList.Model.HttpError err }
          , Effects.none
          )


    UpdateDataFromServer result timestamp' ->
      case result of
        Ok articles ->
          ( { model
            | articles <- articles
            , status <- ArticleList.Model.Fetched timestamp'
            }
          , Effects.none
          )

        Err err ->
          ( { model | status <- ArticleList.Model.HttpError err }
          , Effects.none
          )

    NoOp ->
      (model, Effects.none)

-- EFFECTS

getDataFromCache : ArticleList.Model.Status -> Effects Action
getDataFromCache status =
  let
    actionTask =
      case status of
        ArticleList.Model.Fetched fetchTime ->
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


decodeData : JD.Decoder (List Article.Model)
decodeData =
  JD.at ["data"] <| JD.list <| decodeArticle


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
