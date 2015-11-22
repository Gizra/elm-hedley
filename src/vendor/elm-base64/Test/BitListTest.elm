module Test.BitListTest(tests) where

import BitList exposing (..)
import ElmTest.Assertion exposing (..)
import ElmTest.Test exposing(..)

tests : Test
tests = suite "BitList" [
  defaultTest (fromByte(62) `assertEqual` [Off,Off,On,On,On,On,On,Off]),
  defaultTest (toByte([On,Off]) `assertEqual` 2),
  defaultTest (toByte([Off,On,On,Off]) `assertEqual` 6),
  defaultTest (toByte([Off,Off,On,On,On,On,On,Off]) `assertEqual` 62),
  defaultTest (partition 3 [Off,Off,Off,On,On,Off,On,Off] `assertEqual` [[Off,Off,Off],[On,On,Off],[On,Off]]),
  defaultTest (partition 6 [Off,On,Off,On,Off,Off,Off,Off,Off,Off,Off,Off,Off,Off,Off,Off,Off,Off,Off,Off,Off,Off,Off,Off] `assertEqual` [[Off,On,Off,On,Off,Off],[Off,Off,Off,Off,Off,Off],[Off,Off,Off,Off,Off,Off],[Off,Off,Off,Off,Off,Off]])
  ]
