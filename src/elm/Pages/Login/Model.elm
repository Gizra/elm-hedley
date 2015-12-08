module Pages.Login.Model where

import Http exposing (Error)

type alias AccessToken = String

type alias LoginForm =
  { name: String
  , pass : String
  }

type UserMessage
  = None
  | Error String

type Status
  = Init
  | Fetching
  | Fetched
  | HttpError Http.Error

type alias Model =
  { accessToken: AccessToken
  , hasAccessTokenInStorage : Bool
  , loginForm : LoginForm
  , status : Status
  , userMessage : UserMessage
  }

initialModel : Model
initialModel =
  { accessToken = ""
  -- We start by assuming there's already an access token it the localStorage.
  -- While this property is set to True, the login form will not appear.
  , hasAccessTokenInStorage = True
  , loginForm = LoginForm "demo" "1234"
  , status = Init
  , userMessage = None
  }
