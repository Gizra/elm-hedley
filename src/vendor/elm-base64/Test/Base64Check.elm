module Test.Base64Check where

import Base64 exposing (encode, decode)
import Random.String exposing (rangeLengthString)
import Random.Char exposing (char)
import Check exposing (..)
import Result exposing (..)
import Random exposing (..)
import Shrink exposing (noShrink)


claim_reverse_twice_yields_original =
  claim
    "Base64 encoding and then decoding yields the original String"
  `that`
    (\string ->
       let
         encoded = encode string
       in
         case encoded of
           Ok x -> decode x
           Err y -> Err y)
  `is`
    (\string -> Ok string)
  `for`
      {generator = generatorAscii, shrinker = noShrink}

generatorAscii : Generator String
generatorAscii = rangeLengthString 0 300 (char 32 126)

checks =
  suite "Base64 check suite"
    [ claim_reverse_twice_yields_original ]
