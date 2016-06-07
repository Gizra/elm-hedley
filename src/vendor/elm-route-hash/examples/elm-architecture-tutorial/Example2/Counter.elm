module Example2.Counter exposing (Model, init, Action, update, view, delta2update, location2action)

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import RouteHash exposing (HashUpdate)
import String exposing (toInt)


-- MODEL

type alias Model = Int


init : Int -> Model
init count = count


-- UPDATE

-- We add a Set action for the advanced example, so that we
-- can restore a particular bookmarked state.
type Action
    = Increment
    | Decrement
    | Set Int


update : Action -> Model -> Model
update action model =
  case action of
    Increment -> model + 1
    Decrement -> model - 1
    Set value -> value


-- VIEW

view : Model -> Html Action
view model =
  div []
    [ button [ onClick Decrement ] [ text "-" ]
    , div [ countStyle ] [ text (toString model) ]
    , button [ onClick Increment ] [ text "+" ]
    ]


countStyle : Attribute any
countStyle =
  style
    [ ("font-size", "20px")
    , ("font-family", "monospace")
    , ("display", "inline-block")
    , ("width", "50px")
    , ("text-align", "center")
    ]


-- Routing

-- For delta2update, we provide our state as the value for the URL
delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
    Just <|
        RouteHash.set [toString current]


-- For location2action, we generate an action that will restore our state
location2action : List String -> List Action
location2action list =
    case list of
        first :: rest ->
            case toInt first of
                Ok value ->
                    [ Set value ]

                Err _ ->
                    -- If it wasn't an integer, then no action
                    []

        _ ->
            -- If nothing provided for this part of the URL, return empty list 
            []
