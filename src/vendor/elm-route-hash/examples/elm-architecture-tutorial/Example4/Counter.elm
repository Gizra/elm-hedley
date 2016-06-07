module Example4.Counter exposing (Model, init, Action, update, view, viewWithRemoveButton, Context)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App exposing (map)


-- MODEL

type alias Model = Int


init : Int -> Model
init count = count


-- UPDATE

type Action = Increment | Decrement


update : Action -> Model -> Model
update action model =
  case action of
    Increment -> model + 1
    Decrement -> model - 1


-- VIEW

view : Model -> Html Action
view model =
  div []
    [ button [ onClick Decrement ] [ text "-" ]
    , div [ countStyle ] [ text (toString model) ]
    , button [ onClick Increment ] [ text "+" ]
    ]


type alias Context super =
    { modify : Action -> super
    , remove : super
    }


viewWithRemoveButton : Context super -> Model -> Html super
viewWithRemoveButton context model =
  div []
    [ map context.modify (button [ onClick Decrement ] [ text "-" ])
    , div [ countStyle ] [ text (toString model) ]
    , map context.modify (button [ onClick Increment ] [ text "+" ])
    , div [ countStyle ] []
    , button [ onClick context.remove ] [ text "X" ]
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
