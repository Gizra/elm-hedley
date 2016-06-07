module Example8.SpinSquare exposing
    (Model, Action, init, update, view, delta2update, location2action, subscriptions)

import Ease exposing (outBounce)
import Html exposing (Html)
import Svg exposing (svg, rect, g, text, text')
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)
import Time exposing (Time, second)
import RouteHash exposing (HashUpdate)
import AnimationFrame
import String


-- MODEL

type alias Model =
    { angle : Float
    , animationState : Maybe Time
    }


init : (Model, Cmd Action)
init =
  ( { angle = 0, animationState = Nothing }
  , Cmd.none
  )


rotateStep = 90
duration = second


-- UPDATE

-- For the advanced example, allow setting the angle directly
type Action
    = Spin
    | Tick Time
    | SetAngle Float


subscriptions : Model -> Sub Action
subscriptions model =
    case model.animationState of
        Just _ ->
            AnimationFrame.diffs Tick

        Nothing ->
            Sub.none


update : Action -> Model -> (Model, Cmd Action)
update msg model =
  case msg of
    Spin ->
      case model.animationState of
        Nothing ->
          ( { model | animationState = Just 0 }
          , Cmd.none
          )

        Just _ ->
          ( model, Cmd.none )

    Tick diff ->
      let
        newElapsedTime =
          case model.animationState of
            Nothing ->
              0

            Just elapsedTime ->
              elapsedTime + diff

      in
        if newElapsedTime > duration then
          ( { angle = model.angle + rotateStep
            , animationState = Nothing
            }
          , Cmd.none
          )
        else
          ( { angle = model.angle
            , animationState = Just newElapsedTime
            }
          , Cmd.none
          )

    SetAngle angle ->
        ( { angle = angle
          , animationState = Nothing
          }
        , Cmd.none
        )


-- VIEW

toOffset : Maybe Time -> Float
toOffset animationState =
  case animationState of
    Nothing ->
      0

    Just elapsedTime ->
      (outBounce (elapsedTime / duration)) * rotateStep


view : Model -> Html Action
view model =
  let
    angle =
      model.angle + toOffset model.animationState
  in
    svg
      [ width "200", height "200", viewBox "0 0 200 200" ]
      [ g [ transform ("translate(100, 100) rotate(" ++ toString angle ++ ")")
          , onClick Spin
          ]
          [ rect
              [ x "-50"
              , y "-50"
              , width "100"
              , height "100"
              , rx "15"
              , ry "15"
              , style "fill: #60B5CC;"
              ]
              []
          , text' [ fill "white", textAnchor "middle" ] [ text "Click me!" ]
          ]
      ]


-- Routing

-- Again, we don't necessarily need to use the same signature always ...
delta2update : Model -> Maybe String
delta2update current =
    -- We only want to update if our animation state is Nothing
    if current.animationState == Nothing
        then
            Just <|
                toString current.angle

        else
            Nothing


location2action : String -> Maybe Action
location2action location =
    Maybe.map SetAngle <|
        Result.toMaybe <|
            String.toFloat location
