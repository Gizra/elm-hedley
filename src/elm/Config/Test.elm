module Config.Test where

import ElmTest exposing (..)

import Config.Model exposing (initialBackendConfig, initialModel, Model)
import Config.Update exposing (update, Action)
import Effects exposing (Effects)

type alias Action = Config.Update.Action
type alias Model = Config.Model.Model

setErrorTest : Test
setErrorTest =
  test "set error action" (assertEqual True (.error <| fst(setError)))

setError : (Model, Effects Action)
setError =
  Config.Update.update Config.Update.SetError initialModel


all : Test
all =
  suite "Config tests"
    [ setErrorTest
    ]
