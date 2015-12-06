module ArticleForm.Model where

-- import Config exposing (cacheTtl)
-- import ConfigType exposing (BackendConfig)
-- import Effects exposing (Effects)
-- import Html exposing (i, button, div, label, h2, h3, input, img, li, text, textarea, span, ul, Html)
-- import Html.Attributes exposing (action, class, id, disabled, name, placeholder, property, required, size, src, style, type', value)
-- import Html.Events exposing (on, onClick, onSubmit, targetValue)
-- import Http exposing (post)
-- import Json.Decode as JD exposing ((:=))
-- import Json.Encode as JE exposing (string)
-- import String exposing (toInt, toFloat)
-- import Task  exposing (andThen, Task)
-- import TaskTutorial exposing (getCurrentTime)
-- import Time exposing (Time)
-- import Utils.Http exposing (getErrorMessageFromHttpResponse)

import Debug

-- MODEL

type alias Id = Int

type Status =
  Init
  | Fetching
  | Fetched Time.Time
  | HttpError Http.Error

type PostStatus = Busy | Done | Ready

type UserMessage
  = None
  | Error String


type alias Author =
  { id : Id
  , name : String
  }

type alias Article =
  { author : Author
  , body : String
  , id : Id
  , image : Maybe String
  , label : String
  }

type alias ArticleForm =
  { label : String
  , body : String
  , image : Maybe Int
  , show : Bool
  }

initialArticleForm : ArticleForm
initialArticleForm =
  { label = ""
  , body = ""
  , image = Nothing
  , show = True
  }

type alias Model =
  { articleForm : ArticleForm
  , articles : List Article
  , postStatus : PostStatus
  , status : Status
  , userMessage : UserMessage
  }

initialModel : Model
initialModel =
  { articleForm = initialArticleForm
  , articles = []
  , postStatus = Ready
  , status = Init
  , userMessage = None
  }

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )
