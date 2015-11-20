import App exposing (init, update, view)
import Article exposing (Action, PostStatus)
import StartApp as StartApp
import Effects exposing (Never)
import Event exposing (Action)
import Leaflet exposing (Action, Model)
import RouteHash
import Task exposing (Task)


app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs =
        [ messages.signal
        , Signal.map (App.ChildArticleAction << Article.SetImageId) dropzoneUploadedFile
        , Signal.map (App.ChildEventAction << Event.SelectEvent) selectEvent
        ]
    }

main =
  app.html

messages : Signal.Mailbox App.Action
messages =
    Signal.mailbox App.NoOp

port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks

port routeTasks : Signal (Task () ())
port routeTasks =
  RouteHash.start
    { prefix = RouteHash.defaultPrefix
    , address = messages.address
    , models = app.model
    , delta2update = App.delta2update
    , location2action = App.location2action
    }

-- Interactions with Leaflet maps

type alias LeafletPort =
  { leaflet : Leaflet.Model
  , events : List Int
  }

port mapManager : Signal LeafletPort
port mapManager =
  let
    getEvents model =
      (.events >> .events) model

    getLeaflet model =
      (.events >> .leaflet) model

    getLeafletPort model =
      { events = List.map .id <| getEvents model
      , leaflet = getLeaflet model
      }

  in
    Signal.map getLeafletPort app.model

port selectEvent : Signal (Maybe Int)

-- Dropzone

type alias ActivePagePort =
  { accessToken : String
  , activePage : String
  , backendUrl : String
  , postStatus : String
  }

port activePage : Signal ActivePagePort
port activePage =
  let
    pageAsString page =
      case page of
        App.Article -> "Article"
        App.Event _ -> "Event"
        App.GithubAuth -> "GithubAuth"
        App.Login -> "Login"
        App.PageNotFound -> "PageNotFound"
        App.User -> "User"

    postStatusAsString status =
      case status of
        Article.Busy -> "Busy"
        Article.Done -> "Done"
        Article.Ready -> "Ready"

    getPortData model =
      { accessToken = model.accessToken
      , activePage = pageAsString model.activePage
      , backendUrl = (.config >> .backendConfig >> .backendUrl) model
      , postStatus = postStatusAsString model.article.postStatus
      }
  in
    Signal.map getPortData app.model

port dropzoneUploadedFile : Signal (Maybe Int)
