module Ascii (fromInt, toInt, isValid) where

import Array exposing (Array)
import String
import Dict exposing (Dict)
import List
import Maybe
import Result
import Result exposing (fromMaybe)


fromInt : Int -> Result String Char
fromInt int =
  let array = Array.fromList asciiCharsList
  in
    fromMaybe "integer has no corresponding ascii char" (Array.get (int-32) array)

toInt : Char -> Result String Int
toInt char =
  fromMaybe "char is not a supported ascii character" (Dict.get char asciiCharsMap)

isValid : String -> Bool
isValid string =
  let isAsciiChar char = Dict.member char asciiCharsMap
  in
    List.all isAsciiChar (String.toList string)

asciiCharsList : List Char
asciiCharsList =
  String.toList " !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"

asciiCharsMap : Dict Char Int
asciiCharsMap =
  let pairs = List.map2 (,) asciiCharsList [32..126]
      addToDict (key,value) dict = Dict.insert key value dict
  in
    List.foldl addToDict Dict.empty pairs
