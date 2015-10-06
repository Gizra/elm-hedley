
import Effects exposing (Never)
import App exposing (init, update, view)
import Event exposing (Action)
import Leaflet exposing (Action, Model)
import StartApp
import Task


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

type alias LeafletPort =
  { leaflet : Leaflet.Model
  , events : List Int
  }

-- Interactions with Leaflet maps
port mapManager : Signal LeafletPort
port mapManager =
  let

    getLeaflet model =
      (.events >> .leaflet) model

    getEvents model =
      (.events >> .events) model

    val model = LeafletPort
      (getLeaflet model)
      (List.map .id (getEvents model))

  in
  Signal.map val app.model

port selectEvent : Signal (Maybe Int)
