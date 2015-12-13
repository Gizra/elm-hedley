module Main where

import Graphics.Element exposing (Element)

import ElmTest exposing (..)

import Config.Test as Config
import EventTest as Event
import Pages.Login.Test as Login


allTests : Test
allTests =
  suite "All tests"
    [ Config.all
    , Event.all
    , Login.all
    ]

main : Element
main =
  elementRunner allTests
