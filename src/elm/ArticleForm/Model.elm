module ArticleForm.Model where

type PostStatus = Busy | Done | Ready

type alias ArticleForm =
  { label : String
  , body : String
  , image : Maybe Int
  , show : Bool
  }

type UserMessage
  = None
  | Error String

type alias Model =
  { articleForm : ArticleForm
  , postStatus : PostStatus
  , userMessage : UserMessage
  }

initialArticleForm : ArticleForm
initialArticleForm =
  { label = ""
  , body = ""
  , image = Nothing
  , show = True
  }

initialModel : Model
initialModel =
  { articleForm = initialArticleForm
  , postStatus = Ready
  , userMessage = None
  }
