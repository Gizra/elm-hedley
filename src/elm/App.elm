module App where


import Company exposing (..)
import Effects exposing (Effects, Never)
import Event exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Task exposing (..)
import User exposing (..)

import Debug

-- MODEL

type alias AccessToken = String

type Page
  = Event
  | User
  | MyAccount

type alias Model =
  { user : User.Model
  , companies : List Company.Model
  , events : Event.Model
  , activePage : Page
  }

initialModel : Model
initialModel =
  { user = User.initialModel
  , companies = []
  , events = Event.initialModel
  , activePage = User
  }

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

-- UPDATE

type Action
  = ChildEventAction Event.Action
  | ChildUserAction User.Action
  | SetActivePage Page

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    ChildEventAction act ->
      let
        -- Pass the access token along to child components.
        context = { accessToken = (.user >> .accessToken) model }
        (childModel, childEffects) = Event.update context act model.events
      in
        ( {model | events <- childModel }
        , Effects.map ChildEventAction childEffects
        )

    ChildUserAction act ->
      let
        (childModel, childEffects) = User.update act model.user

        defaultEffects =
          [ Effects.map ChildUserAction childEffects ]

        effects =
          case act of
            User.UpdateDataFromServer result ->
              case result of
                Ok _ ->
                  -- User was successfully logged in, so we can redirect to the
                  -- events page.
                  (Task.succeed (SetActivePage Event) |> Effects.task) :: defaultEffects

                Err _ ->
                  defaultEffects

            _ ->
              defaultEffects

      in
        ( { model | user <- childModel }
        , Effects.batch effects
        )

    SetActivePage page ->
      let
        currentPageEffects =
          case model.activePage of
            User ->
              Task.succeed (ChildUserAction User.Deactivate) |> Effects.task

            Event ->
              Task.succeed (ChildEventAction Event.Deactivate) |> Effects.task

        newPageEffects =
          case page of
            User ->
              Task.succeed (ChildUserAction User.Activate) |> Effects.task

            Event ->
              Task.succeed (ChildEventAction Event.Activate) |> Effects.task

      in
        ( { model | activePage <- page}
        , Effects.batch
          [ currentPageEffects
          , newPageEffects
          ]
        )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  div []
    [ (navbar address model)
    , (mainContent address model)
    ]

mainContent : Signal.Address Action -> Model -> Html
mainContent address model =
  case model.activePage of
    User ->
      let
        childAddress =
          Signal.forwardTo address ChildUserAction
      in
        div [ style myStyle ] [ User.view childAddress model.user ]

    MyAccount ->
      let
        model' = { model | activePage <- User }
      in
      view address model'

    Event ->
      let
        childAddress =
          Signal.forwardTo address ChildEventAction
      in
        div [ style myStyle ] [ Event.view childAddress model.events ]

navbar : Signal.Address Action -> Model -> Html
navbar address model =
  case model.user.name of
    Anonymous ->
      div [] []

    LoggedIn name ->
      navbarLoggedIn address model

-- Navbar for Auth user.
navbarLoggedIn : Signal.Address Action -> Model -> Html
navbarLoggedIn address model =
  node "nav" [class "navbar navbar-default"]
    [ div [class "container-fluid"]
      -- Brand and toggle get grouped for better mobile display
        [ div [class "navbar-header"] []
        , div [ class "collapse navbar-collapse"]
            [ ul [class "nav navbar-nav"]
              [ li [] [ a [ href "#", onClick address (SetActivePage User) ] [ text "My account"] ]
              , li [] [ a [ href "#", onClick address (SetActivePage Event)] [ text "Events"] ]
              ]

            ]

        ]

    ]

myStyle : List (String, String)
myStyle =
    [ ("padding", "10px")
    , ("margin", "50px")
    , ("font-size", "2em")
    ]
