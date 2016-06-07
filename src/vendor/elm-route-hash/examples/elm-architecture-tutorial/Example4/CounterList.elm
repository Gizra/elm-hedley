module Example4.CounterList exposing (..)

import Example4.Counter as Counter
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import RouteHash exposing (HashUpdate)
import Result.Extra
import String


-- MODEL

type alias Model =
    { counters : List ( ID, Counter.Model )
    , nextID : ID
    }

type alias ID = Int


init : Model
init =
    { counters = []
    , nextID = 0
    }


-- UPDATE

-- Add an action for the advanced example to set our state from a `list int`
type Action
    = Insert
    | Remove ID
    | Modify ID Counter.Action
    | Set (List Int)


update : Action -> Model -> Model
update action model =
  case action of
    Insert ->
      { model |
          counters = ( model.nextID, Counter.init 0 ) :: model.counters,
          nextID = model.nextID + 1
      }

    Remove id ->
      { model |
          counters = List.filter (\(counterID, _) -> counterID /= id) model.counters
      }

    Modify id counterAction ->
      let updateCounter (counterID, counterModel) =
            if counterID == id
                then (counterID, Counter.update counterAction counterModel)
                else (counterID, counterModel)
      in
          { model | counters = List.map updateCounter model.counters }

    Set list ->
        let
            counters =
                List.indexedMap (\index item ->
                    (index, Counter.init item)
                ) list

        in
            { counters = counters
            , nextID = List.length counters
            }


-- VIEW

view : Model -> Html Action
view model =
  let insert = button [ onClick Insert ] [ text "Add" ]
  in
      div [] (insert :: List.map viewCounter model.counters)


viewCounter : (ID, Counter.Model) -> Html Action
viewCounter (id, model) =
  let context =
        Counter.Context (Modify id) (Remove id)
  in
      Counter.viewWithRemoveButton context model


-- We add a separate function to get a title, which the ExampleViewer uses to
-- construct a table of contents. Sometimes, you might have a function of this
-- kind return `Html` instead, depending on where it makes sense to do some of
-- the construction. Or, you could track the title in the higher level module,
-- if you prefer that.
title : String
title = "List of Counters (individually removable)"


-- Routing

-- You could do this in a variety of ways. We'll ignore the ID's, and just
-- encode the value of each Counter in the list -- so we'll end up with
-- something like /0/1/5 or whatever. When we recreate that, we won't
-- necessarily have the same IDs, but that doesn't matter for this example.
-- If it mattered, we'd have to do this a different way.
delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
    -- We'll take advantage of the fact that we know that the counter
    -- is just an Int ... no need to be super-modular here.
    List.map (toString << snd) current.counters
        |> RouteHash.set
        |> Just


location2action : List String -> List Action
location2action list =
    let
        result =
            List.map String.toInt list
                |> Result.Extra.combine

    in
        case result of
            Ok ints ->
                [ Set ints ]

            Err _ ->
                []
