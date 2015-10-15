import App exposing (init, update, view)
import CustomStartApp as StartApp
import Effects exposing (Never)
import Event exposing (Action)
import Leaflet exposing (Action, Model)
import RouteHash
import Task exposing (Task)


app : StartApp.App App.Model App.Action
app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs = [Signal.map (App.ChildEventAction << Event.SelectEvent) selectEvent]
    }

main =
  app.html


port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks

port routeTasks : Signal (Task () ())
port routeTasks =
    RouteHash.start
        { prefix = RouteHash.defaultPrefix
        , address = app.address
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

    getLeaflet model =
      (.events >> .leaflet) model

    getEvents model =
      (.events >> .events) model

    getLeafletPort model =
      LeafletPort (getLeaflet model) (List.map .id (getEvents model))

  in
  Signal.map getLeafletPort app.model

port selectEvent : Signal (Maybe Int)
