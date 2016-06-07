import ExampleViewer
import RouteHash


main : Program Never
main =
    RouteHash.program
        { prefix = RouteHash.defaultPrefix
        , delta2update = ExampleViewer.delta2update
        , location2action = ExampleViewer.location2action
        , init = ExampleViewer.init
        , update = ExampleViewer.update
        , view = ExampleViewer.view
        , subscriptions = ExampleViewer.subscriptions 
        }
