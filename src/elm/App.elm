module App where


import Company exposing (..)
import Effects exposing (Effects, Never)
import Event exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Task exposing (..)
import User exposing (..)

import Debug

type alias AccessToken = String

type alias Model =
  { user : User.Model
  , companies : List Company.Model
  , events : Event.Model
  , accessToken : AccessToken
  }

initialModel : Model
initialModel =
  Model User.initialModel [] Event.initialModel ""

init : (Model, Effects Action)
init =
  let
    eventEffects = snd Event.init
    userEffects = snd User.init
  in
    ( initialModel
    , Effects.batch
      [ Effects.map ChildEventAction eventEffects
      , Effects.map ChildUserAction userEffects
      ]
    )

type Action
  = SetAccessToken AccessToken
  | ChildUserAction User.Action
  | ChildEventAction Event.Action


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of

    -- @todo: Find how child can call this.
    SetAccessToken accessToken ->
      ( {model | accessToken <- accessToken}
      , Effects.none
      )

    ChildUserAction act ->
      let
        (childModel, childEffects) = User.update act model.user
      in
        ( {model | user <- childModel}
        , Effects.batch
            [ Effects.map ChildUserAction childEffects
            -- @todo: Where to move this so it's invoked on time?
            , Task.succeed (ChildEventAction Event.GetDataFromServer) |> Effects.task
            ]
        )

    ChildEventAction act ->
      let
        (childModel, childEffects) = Event.update act model.events
      in
        ( {model | events <- childModel }
        , Effects.map ChildEventAction childEffects
        )

-- VIEW

(=>) = (,)

view : Signal.Address Action -> Model -> Html
view address model =
  case model.user.name of
    Anonymous ->
      let
        childAddress =
          Signal.forwardTo address ChildUserAction
      in
        div [ style myStyle ] [ User.view childAddress model.user ]

    LoggedIn name ->
      let
        childAddress =
          Signal.forwardTo address ChildEventAction
      in
        div [ style myStyle ] [ Event.view childAddress model.events ]

rootModelView : Model -> Html
rootModelView model =
  div [] []

myStyle : List (String, String)
myStyle =
    [ ("padding", "10px")
    , ("margin", "50px")
    , ("font-size", "2em")
    ]
