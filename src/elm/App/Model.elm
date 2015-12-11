module App.Model where

import Config.Model exposing (initialModel, Model)
import Company exposing (Model)
import Event exposing (Model, initialModel, update)
import GithubAuth exposing (Model)

-- Pages import

import Pages.Article.Model as Article exposing (initialModel, Model)
import Pages.Login.Model as Login exposing (initialModel, Model)
import Pages.User.Model as User exposing(..)

type alias AccessToken = String
type alias CompanyId = Int

type Page
  = Article
  | Event (Maybe CompanyId)
  | GithubAuth
  | Login
  | PageNotFound
  | User

type alias Model =
  { accessToken : AccessToken
  , activePage : Page
  , article : Article.Model
  , config : Config.Model.Model
  , configError : Bool
  , companies : List Company.Model
  , events : Event.Model
  , githubAuth: GithubAuth.Model
  , login: Login.Model
  -- If the user is anonymous, we want to know where to redirect them.
  , nextPage : Maybe Page
  , user : User.Model
  }

initialModel : Model
initialModel =
  { accessToken = ""
  , activePage = Login
  , article = Article.initialModel
  , config = Config.Model.initialModel
  , configError = False
  , companies = []
  , events = Event.initialModel
  , githubAuth = GithubAuth.initialModel
  , login = Login.initialModel
  , nextPage = Nothing
  , user = User.initialModel
  }
