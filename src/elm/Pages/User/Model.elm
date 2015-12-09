module Pages.User.Model where

import Company exposing (..)
import Effects exposing (Effects)
import Http exposing (Error)
import String
import Task

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

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )

type Action
  = GetDataFromServer
  | NoOp (Maybe ())
  | SetAccessToken AccessToken
  | UpdateDataFromServer (Result Http.Error (Id, String, List Company.Model))
