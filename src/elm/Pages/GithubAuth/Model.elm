module Pages.GithubAuth.Model where

import Http exposing (Error)

type alias AccessToken = String

type Status = Init
  | Error String
  | Fetching
  | Fetched
  | HttpError Http.Error


type alias Model =
  { accessToken: AccessToken
  , status : Status
  , code : Maybe String
  }

initialModel : Model
initialModel =
  { accessToken = ""
  , status = Init
  , code = Nothing
  }
