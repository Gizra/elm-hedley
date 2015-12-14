module Pages.Login.Test where

import ElmTest exposing (..)

import Config.Model exposing (initialBackendConfig)
import Effects exposing (Effects)
import Http exposing (Error)
import Pages.Login.Model exposing (initialModel, Model)
import Pages.Login.Update exposing (Action)

type alias Model = Pages.Login.Model.Model

accessTokenSuite : Test
accessTokenSuite =
  let
    pass =
      .loginForm >> .pass
  in
    suite "Set access token tests"
      [ test "on empty set access token, password is reset" (assertEqual "" (pass <| fst(setAccessToken "")))
      , test "on set access token, password is reset" (assertEqual "" (pass <| fst(setAccessToken "accessToken")))
      ]

formSuite : Test
formSuite =
  let
    -- Shorthand, to get to the form's properties.
    name =
      .loginForm >> .name

    pass =
      .loginForm >> .pass
  in
    suite "Login form tests"
      [ test "empty name" (assertEqual "" (name <| fst(updateName "")))
      , test "simple name" (assertEqual "foo" (name <| fst(updateName "foo")))
      -- Password
      , test "empty password" (assertEqual "" (pass <| fst(updatePass "")))
      , test "simple password" (assertEqual "bar" (pass <| fst(updatePass "bar")))

      -- Submit form
      , test "first submit, status is Fetching" (assertEqual Pages.Login.Model.Fetching (.status <| fst(submitForm Pages.Login.Model.Init)))
      , test "ongoing submit" (assertEqual Pages.Login.Model.Fetching (.status <| fst(submitForm Pages.Login.Model.Fetching)))
      , test "submit done without errors" (assertEqual Pages.Login.Model.Fetched (.status <| fst(submitForm Pages.Login.Model.Fetched)))
      , test "submit after another submit with errors" (assertEqual Pages.Login.Model.Fetching (.status <| fst(submitForm <| Pages.Login.Model.HttpError Http.NetworkError)))
      ]

updateName : String -> (Model, Effects Action)
updateName val =
  Pages.Login.Update.update updateContext (Pages.Login.Update.UpdateName val) Pages.Login.Model.initialModel

updatePass : String -> (Model, Effects Action)
updatePass val =
  Pages.Login.Update.update updateContext (Pages.Login.Update.UpdatePass val) Pages.Login.Model.initialModel

submitForm : Pages.Login.Model.Status -> (Model, Effects Action)
submitForm status =
  let
    model =
      Pages.Login.Model.initialModel

    model' =
      { model | status = status }

  in
    Pages.Login.Update.update updateContext Pages.Login.Update.SubmitForm model'

setAccessToken : String -> (Model, Effects Action)
setAccessToken val =
  Pages.Login.Update.update updateContext (Pages.Login.Update.SetAccessToken val) Pages.Login.Model.initialModel


updateContext : Pages.Login.Update.Context
updateContext =
  { backendConfig = initialBackendConfig
  }

all : Test
all =
  suite "All Login tests"
    [ accessTokenSuite
    , formSuite
    ]
