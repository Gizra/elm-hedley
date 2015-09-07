
import Effects exposing (Never)
import User exposing (init, update, view)
import StartApp
import Task


app =
  StartApp.start
    { init = User.init
    , update = User.update
    , view = User.view
    , inputs = []
    }


main =
  app.html


port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks
