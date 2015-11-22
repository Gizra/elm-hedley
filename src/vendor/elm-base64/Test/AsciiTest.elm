module Test.AsciiTest(tests) where

import Ascii
import List
import Result
import ElmTest.Assertion exposing (..)
import ElmTest.Test exposing(..)


fromIntTest : (Char, Int) -> Test
fromIntTest (char,int) =
  defaultTest (assertEqual (Ascii.fromInt int) (Result.Ok char))

toIntTest : (Char, Int) -> Test
toIntTest (char,int) =
  defaultTest (assertEqual (Ascii.toInt char) (Result.Ok int))

examples =
  [ (' ', 32)
  , ('.', 46)
  , (']', 93)
  , ('a', 97)
  , ('~', 126)
  ]

tests : Test
tests =
  suite "Ascii" [ suite "toInt" <| List.map toIntTest examples
                , suite "fromInt" <| List.map fromIntTest examples
                ]
