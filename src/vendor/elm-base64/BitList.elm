module BitList where

import List exposing (..)


type Bit = On | Off

fromNumber : Int -> List Bit
fromNumber int =
  if | int == 0     -> []
     | int % 2 == 1 -> fromNumber(int//2) `append` [On]
     | int % 2 == 0 -> fromNumber(int//2) `append` [Off]

fromNumberWithSize : Int -> Int -> List Bit
fromNumberWithSize number size =
  let
    bitList = fromNumber number
    paddingSize = size - length bitList
  in
    repeat paddingSize Off `append` bitList

fromByte : Int -> List Bit
fromByte byte = fromNumberWithSize byte 8

toByte : List Bit -> Int
toByte bitList = toByteReverse <| reverse bitList

toByteReverse : List Bit -> Int
toByteReverse bitList = case bitList of
  []          -> 0
  Off :: tail -> 2 * toByteReverse tail
  On :: tail  -> 1 + 2 * toByteReverse tail

partition : Int -> List Bit -> List(List Bit)
partition size list =
  if length list <= size
  then [list]
  else take size list :: partition size (drop size list)
