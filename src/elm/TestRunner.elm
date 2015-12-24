module Main where

import Graphics.Element exposing (Element)

import ElmTest exposing (..)

import Config.Test as Config
import EventCompanyFilter.Test as EventCompanyFilter
import Pages.Login.Test as Login


allTests : Test
allTests =
  suite "All tests"
    [ Config.all
    , EventCompanyFilter.all
    , Login.all
    ]

main : Element
main =
  elementRunner allTests
