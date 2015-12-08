module Main where

import Graphics.Element exposing (Element)

import ElmTest.Test exposing (Test, suite)
import ElmTest.Runner.Element exposing (runDisplay)

import EventTest as Event
import Pages.Login.Test as Login

allTests : Test
allTests =
  suite "All tests"
    [ Event.all
    , Login.all
    ]

main : Element
main =
  runDisplay allTests
