module Example1.Counter exposing (..)

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import RouteHash exposing (HashUpdate)
import String exposing (toInt)


-- MODEL

type alias Model = Int


-- Added from Main.elm
init : Model
init = 0


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


-- We add a separate function to get a title, which the ExampleViewer uses to
-- construct a table of contents. Sometimes, you might have a function of this
-- kind return `Html` instead, depending on where it makes sense to do some of
-- the construction.
title : String
title = "Counter"


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
                    -- If it wasn't an integer, then no action ... we could
                    -- show an error instead, of course.
                    []

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []
