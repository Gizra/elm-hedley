module App where


import Company exposing (..)
import Effects exposing (Effects, Never)
import Html exposing (..)
import User exposing (..)

type alias AccessToken = String

type alias Model =
  { user : User.Model
  , companies : List Company.Model
  , accessToken : AccessToken
  }

initialModel : Model
initialModel =
  Model User.initialModel [] ""

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )

type Action
  = SetAccessToken AccessToken
  | ChildUserAction User.Action


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
        (userModel, userEffects) = User.update act model.user
      in
      ( {model | user <- userModel, accessToken <- userModel.accessToken}
      , Effects.map ChildUserAction userEffects
      )

-- VIEW

(=>) = (,)

view : Signal.Address Action -> Model -> Html
view address model =
  let
    childAddress =
      Signal.forwardTo address ChildUserAction
  in
    User.view childAddress model.user
