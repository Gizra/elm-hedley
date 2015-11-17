module LoginTest where

import ElmTest.Assertion exposing (..)
import ElmTest.Test exposing (..)

import ConfigType exposing (initialBackendConfig)
import Effects exposing (Effects)
import Http exposing (..)
import Login exposing (Model)

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
      , test "first submit, status is Fetching" (assertEqual Login.Fetching (.status <| fst(submitForm Login.Init)))
      , test "ongoing submit" (assertEqual Login.Fetching (.status <| fst(submitForm Login.Fetching)))
      , test "submit done without errors" (assertEqual Login.Fetched (.status <| fst(submitForm Login.Fetched)))
      , test "submit after another submit with errors" (assertEqual Login.Fetching (.status <| fst(submitForm <| Login.HttpError NetworkError)))
      ]

updateName : String -> (Login.Model, Effects Login.Action)
updateName val =
  Login.update updateContext (Login.UpdateName val) Login.initialModel

updatePass : String -> (Login.Model, Effects Login.Action)
updatePass val =
  Login.update updateContext (Login.UpdatePass val) Login.initialModel

submitForm : Login.Status -> (Login.Model, Effects Login.Action)
submitForm status =
  let
    model =
      Login.initialModel

    model' =
      { model | status <- status }

  in
    Login.update updateContext Login.SubmitForm model'

setAccessToken : String -> (Login.Model, Effects Login.Action)
setAccessToken val =
  Login.update updateContext (Login.SetAccessToken val) Login.initialModel


updateContext : Login.UpdateContext
updateContext =
  { backendConfig = ConfigType.initialBackendConfig
  }

all : Test
all =
  suite "All Login tests"
    [ accessTokenSuite
    , formSuite
    ]
