module Main where

import Graphics.Element exposing (Element)

import ElmTest.Test exposing (Test, suite)
import ElmTest.Runner.Element exposing (runDisplay)

import EventTest
import LoginTest

allTests : Test
allTests =
  suite "All tests"
    [ EventTest.all
    , LoginTest.all
    ]

main : Element
main =
  runDisplay allTests
