module Pages.User.Model where

import Company.Model as Company exposing (initialModel, Model)
import Http exposing (Error)

type alias Id = Int
type alias AccessToken = String

type User = Anonymous | LoggedIn String

type Status =
  Init
  | Fetching
  | Fetched
  | HttpError Error

type alias Model =
  { name : User
  , id : Id
  , status : Status
  , accessToken : AccessToken

  -- Child components
  , companies : List Company.Model
  }


initialModel : Model
initialModel =
  { name = Anonymous
  , id = 0
  , status = Init
  , accessToken = ""

  -- Child components
  , companies = [Company.initialModel]
  }
