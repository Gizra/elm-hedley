module Shrink
  ( Shrinker
  , noShrink
  , void
  , bool
  , order
  , int
  , atLeastInt
  , float
  , atLeastFloat
  , char
  , atLeastChar
  , character
  , string
  , maybe
  , result
  , list
  , lazylist
  , array
  , tuple
  , tuple3
  , tuple4
  , tuple5
  , convert
  , keepIf
  , dropIf
  , merge
  , map
  , andMap
  ) where
{-| Library containing a collection of basic shrinking strategies and
helper functions to help you construct shrinking strategies.

# Shinker
@docs Shrinker

# Shrinkers
@docs noShrink, void, bool, order, int, atLeastInt, float, atLeastFloat, char, atLeastChar, character, string, maybe, result, lazylist, list, array, tuple, tuple3, tuple4, tuple5

# Useful functions
@docs convert, keepIf, dropIf, merge, map, andMap

-}

import Lazy.List exposing (LazyList, (:::), (+++), empty)
import Lazy exposing (Lazy, force, lazy)
import List
import Array  exposing (Array)
import Char
import String
--import Trampoline exposing (Trampoline(..), trampoline)

{-| Shrinker type.
A shrinker is a function that takes a value and returns a list of values that
are in some sense "smaller" than the given value. If there are no such values
conceptually, then the shrinker should just return the empty list.
-}
type alias Shrinker a = a -> LazyList a

---------------
-- SHRINKERS --
---------------

{-| Empty shrinker. Always returns the empty list.
-}
noShrink : Shrinker a
noShrink _ = empty

{-| Shrink the empty tuple. Equivalent to `noShrink`.
-}
void : Shrinker ()
void = noShrink

{-| Shrinker of bools.
-}
bool : Shrinker Bool
bool b = case b of
  True  ->
    False ::: empty

  False ->
    empty

{-| Shrinker of Order.
-}
order : Shrinker Order
order o = case o of
  GT ->
    EQ ::: LT ::: empty

  LT ->
    EQ ::: empty

  EQ ->
    empty


{-| Shrinker of integers.
-}
int : Shrinker Int
int n =
  if n < 0
  then
    -n ::: Lazy.List.map ((*) -1) (seriesInt 0 -n)
  else
    seriesInt 0 n

{-| Construct a shrinker of ints which considers the given int to
be most minimal.
-}
atLeastInt : Int -> Shrinker Int
atLeastInt min n =
  if n < 0 && n >= min
  then
    -n ::: Lazy.List.map ((*) -1) (seriesInt 0 -n)
  else
    seriesInt (max 0 min) n

{-| Shrinker of floats.
-}
float : Shrinker Float
float n =
  if n < 0
  then
    -n ::: Lazy.List.map ((*) -1) (seriesFloat 0 -n)
  else
    seriesFloat 0 n


{-| Construct a shrinker of floats which considers the given float to
be most minimal.
-}
atLeastFloat : Float -> Shrinker Float
atLeastFloat min n =
  if n < 0 && n >= min
  then
    -n ::: Lazy.List.map ((*) -1) (seriesFloat 0 -n)
  else
    seriesFloat (max 0 min) n


{-| Shrinker of chars.
-}
char : Shrinker Char
char =
  convert Char.fromCode Char.toCode int

{-| Construct a shrinker of chars which considers the given char to
be most minimal.
-}
atLeastChar : Char -> Shrinker Char
atLeastChar char =
  convert Char.fromCode Char.toCode (atLeastInt (Char.toCode char))

{-| Shrinker of chars which considers the empty space as the most
minimal char and omits the control key codes.

Equivalent to:

    atLeastChar (Char.fromCode 32)
-}
character : Shrinker Char
character =
  atLeastChar (Char.fromCode 32)


{-| Shrinker of strings. Considers the empty string to be the most
minimal string and the space to be the most minimal char.

Equivalent to:

    convert String.fromList String.toList (list character)
-}
string : Shrinker String
string =
  convert String.fromList String.toList (list character)


{-| Maybe shrinker constructor.
Takes a shrinker of values and returns a shrinker of Maybes.
-}
maybe : Shrinker a -> Shrinker (Maybe a)
maybe shrink m = case m of
  Just a  ->
    Nothing ::: Lazy.List.map Just (shrink a)

  Nothing ->
    empty

{-| Result shrinker constructor.
Takes a shrinker of errors and a shrinker of values and returns a shrinker
of Results.
-}
result : Shrinker error -> Shrinker value -> Shrinker (Result error value)
result shrinkError shrinkValue r = case r of
  Ok value  ->
    Lazy.List.map Ok  (shrinkValue value)

  Err error ->
    Lazy.List.map Err (shrinkError error)



{-| Lazy List shrinker constructor. (must be finite)
Takes a shrinker of values and returns a shrinker of Lazy Lists.
-}
lazylist : Shrinker a -> Shrinker (LazyList a)
lazylist shrink l = lazy <| \() ->
  let
      -- n : Int
      n =
        Lazy.List.length l

      -- shrinkOne : Shrinker a -> Shrinker (LazyList a)
      shrinkOne l = lazy <| \() ->
        case force l of
        Lazy.List.Nil ->
          force empty
        Lazy.List.Cons x xs ->
          force
            (Lazy.List.map (flip (:::) xs) (shrink x)
            +++ Lazy.List.map ((:::) x) (shrinkOne xs))

      -- removes : Int -> Int -> Shrinker (LazyList a)
      removes k n l = lazy <| \() ->
        if | k > n               -> force empty
           | Lazy.List.isEmpty l -> force (empty ::: empty)
           | otherwise ->
               let
                   first = Lazy.List.take k l -- LazyList a
                   rest  = Lazy.List.drop k l -- LazyList a
               in force <|
                   rest ::: Lazy.List.map ((+++) first) (removes k (n - k) rest)

  in force <|
      Lazy.List.flatMap (\k -> removes k n l)
        (Lazy.List.takeWhile (\x -> x > 0) (Lazy.List.iterate (\n -> n // 2) n))
      +++ shrinkOne l


{-| List shrinker constructor.
Takes a shrinker of values and returns a shrinker of Lists.
-}
list : Shrinker a -> Shrinker (List a)
list shrink =
  convert Lazy.List.toList Lazy.List.fromList (lazylist shrink)

{-| Array shrinker constructor.
Takes a shrinker of values and returns a shrinker of Arrays.
-}
array : Shrinker a -> Shrinker (Array a)
array shrink =
  convert Lazy.List.toArray Lazy.List.fromArray (lazylist shrink)


{-| 2-Tuple shrinker constructor.
Takes a tuple of shrinkers and returns a shrinker of tuples.
-}
tuple : (Shrinker a, Shrinker b) -> Shrinker (a, b)
tuple (shrinkA, shrinkB) (a, b) =
      Lazy.List.map ((,) a) (shrinkB b)
  +++ Lazy.List.map (flip (,) b) (shrinkA a)
  +++ Lazy.List.map2 (,) (shrinkA a) (shrinkB b)



{-| 3-Tuple shrinker constructor.
Takes a tuple of shrinkers and returns a shrinker of tuples.
-}
tuple3 : (Shrinker a, Shrinker b, Shrinker c) -> Shrinker (a, b, c)
tuple3 (shrinkA, shrinkB, shrinkC) (a, b, c) =
      Lazy.List.map  (\c   -> (a,b,c)) (shrinkC c)
  +++ Lazy.List.map  (\b   -> (a,b,c)) (shrinkB b)
  +++ Lazy.List.map  (\a   -> (a,b,c)) (shrinkA a)
  +++ Lazy.List.map2 (\b c -> (a,b,c)) (shrinkB b) (shrinkC c)
  +++ Lazy.List.map2 (\a c -> (a,b,c)) (shrinkA a) (shrinkC c)
  +++ Lazy.List.map2 (\a b -> (a,b,c)) (shrinkA a) (shrinkB b)
  +++ Lazy.List.map3 (,,) (shrinkA a)  (shrinkB b) (shrinkC c)



{-| 4-Tuple shrinker constructor.
Takes a tuple of shrinkers and returns a shrinker of tuples.
-}
tuple4 : (Shrinker a, Shrinker b, Shrinker c, Shrinker d) -> Shrinker (a, b, c, d)
tuple4 (shrinkA, shrinkB, shrinkC, shrinkD) (a, b, c, d) =
      Lazy.List.map  (\d     -> (a,b,c,d)) (shrinkD d)
  +++ Lazy.List.map  (\c     -> (a,b,c,d)) (shrinkC c)
  +++ Lazy.List.map  (\b     -> (a,b,c,d)) (shrinkB b)
  +++ Lazy.List.map  (\a     -> (a,b,c,d)) (shrinkA a)
  +++ Lazy.List.map2 (\c d   -> (a,b,c,d)) (shrinkC c) (shrinkD d)
  +++ Lazy.List.map2 (\b d   -> (a,b,c,d)) (shrinkB b) (shrinkD d)
  +++ Lazy.List.map2 (\a d   -> (a,b,c,d)) (shrinkA a) (shrinkD d)
  +++ Lazy.List.map2 (\b c   -> (a,b,c,d)) (shrinkB b) (shrinkC c)
  +++ Lazy.List.map2 (\a c   -> (a,b,c,d)) (shrinkA a) (shrinkC c)
  +++ Lazy.List.map2 (\a b   -> (a,b,c,d)) (shrinkA a) (shrinkB b)
  +++ Lazy.List.map3 (\b c d -> (a,b,c,d)) (shrinkB b) (shrinkC c) (shrinkD d)
  +++ Lazy.List.map3 (\a c d -> (a,b,c,d)) (shrinkA a) (shrinkC c) (shrinkD d)
  +++ Lazy.List.map3 (\a b c -> (a,b,c,d)) (shrinkA a) (shrinkB b) (shrinkC c)
  +++ Lazy.List.map4 (,,,)     (shrinkA a) (shrinkB b) (shrinkC c) (shrinkD d)





{-| 5-Tuple shrinker constructor.
Takes a tuple of shrinkers and returns a shrinker of tuples.
-}
tuple5 : (Shrinker a, Shrinker b, Shrinker c, Shrinker d, Shrinker e) -> Shrinker (a, b, c, d, e)
tuple5 (shrinkA, shrinkB, shrinkC, shrinkD, shrinkE) (a, b, c, d, e) =
      Lazy.List.map  (\e       -> (a,b,c,d,e)) (shrinkE e)
  +++ Lazy.List.map  (\d       -> (a,b,c,d,e)) (shrinkD d)
  +++ Lazy.List.map  (\c       -> (a,b,c,d,e)) (shrinkC c)
  +++ Lazy.List.map  (\b       -> (a,b,c,d,e)) (shrinkB b)
  +++ Lazy.List.map  (\a       -> (a,b,c,d,e)) (shrinkA a)
  +++ Lazy.List.map2 (\d e     -> (a,b,c,d,e)) (shrinkD d) (shrinkE e)
  +++ Lazy.List.map2 (\c e     -> (a,b,c,d,e)) (shrinkC c) (shrinkE e)
  +++ Lazy.List.map2 (\b e     -> (a,b,c,d,e)) (shrinkB b) (shrinkE e)
  +++ Lazy.List.map2 (\a e     -> (a,b,c,d,e)) (shrinkA a) (shrinkE e)
  +++ Lazy.List.map2 (\c d     -> (a,b,c,d,e)) (shrinkC c) (shrinkD d)
  +++ Lazy.List.map2 (\b d     -> (a,b,c,d,e)) (shrinkB b) (shrinkD d)
  +++ Lazy.List.map2 (\a d     -> (a,b,c,d,e)) (shrinkA a) (shrinkD d)
  +++ Lazy.List.map2 (\b c     -> (a,b,c,d,e)) (shrinkB b) (shrinkC c)
  +++ Lazy.List.map2 (\a c     -> (a,b,c,d,e)) (shrinkA a) (shrinkC c)
  +++ Lazy.List.map2 (\a b     -> (a,b,c,d,e)) (shrinkA a) (shrinkB b)
  +++ Lazy.List.map3 (\c d e   -> (a,b,c,d,e)) (shrinkC c) (shrinkD d) (shrinkE e)
  +++ Lazy.List.map3 (\b d e   -> (a,b,c,d,e)) (shrinkB b) (shrinkD d) (shrinkE e)
  +++ Lazy.List.map3 (\a d e   -> (a,b,c,d,e)) (shrinkA a) (shrinkD d) (shrinkE e)
  +++ Lazy.List.map3 (\a c d   -> (a,b,c,d,e)) (shrinkA a) (shrinkC c) (shrinkD d)
  +++ Lazy.List.map3 (\a b d   -> (a,b,c,d,e)) (shrinkA a) (shrinkB b) (shrinkD d)
  +++ Lazy.List.map3 (\a b c   -> (a,b,c,d,e)) (shrinkA a) (shrinkB b) (shrinkC c)
  +++ Lazy.List.map4 (\b c d e -> (a,b,c,d,e)) (shrinkB b) (shrinkC c) (shrinkD d) (shrinkE e)
  +++ Lazy.List.map4 (\a c d e -> (a,b,c,d,e)) (shrinkA a) (shrinkC c) (shrinkD d) (shrinkE e)
  +++ Lazy.List.map4 (\a b d e -> (a,b,c,d,e)) (shrinkA a) (shrinkB b) (shrinkD d) (shrinkE e)
  +++ Lazy.List.map4 (\a b c d -> (a,b,c,d,e)) (shrinkA a) (shrinkB b) (shrinkC c) (shrinkD d)
  +++ Lazy.List.map5 (,,,,)        (shrinkA a) (shrinkB b) (shrinkC c) (shrinkD d) (shrinkE e)



----------------------
-- HELPER FUNCTIONS --
----------------------

{-| Convert a Shrinker of a's into a Shrinker of b's using two inverse functions.

If you use this function as follows:

    shrinkerB = f g shrinkerA

Make sure that

    `f(g(x)) == x` for all x

Or else this process will generate garbage.
-}
convert : (a -> b) -> (b -> a) -> Shrinker a -> Shrinker b
convert f f' shrink b =
  Lazy.List.map f (shrink (f' b))


{-| Filter out the results of a shrinker. The resulting shrinker
will only produce shrinks which satisfy the given predicate.
-}
keepIf : (a -> Bool) -> Shrinker a -> Shrinker a
keepIf predicate shrink a =
  Lazy.List.keepIf predicate (shrink a)

{-| Filter out the results of a shrinker. The resulting shrinker
will only throw away shrinks which satisfy the given predicate.
-}
dropIf : (a -> Bool) -> Shrinker a -> Shrinker a
dropIf predicate =
  keepIf (not << predicate)


{-| Merge two shrinkers.
-}
merge : Shrinker a -> Shrinker a -> Shrinker a
merge shrink1 shrink2 a =
  Lazy.List.unique
    (shrink1 a +++ shrink2 a)

{-| Re-export of `Lazy.List.map`
This is useful in order to compose shrinkers, especially when used in
conjunction with `andMap`.
Example:
    type alias Vector =
      { x : Float
      , y : Float
      , z : Float
      }
    vector : Shrinker Float
    vector {x,y,z} =
      Vector
        `map`    float x
        `andMap` float y
        `andMap` float z
-}
map : (a -> b) -> LazyList a -> LazyList b
map =
  Lazy.List.map


{-| Apply a lazy list of functions on a lazy list of values.
    andMap = Lazy.List.map2 (<|)
This is useful in order to compose shrinkers, especially when used in
conjunction with `andMap`.
-}
andMap : LazyList (a -> b) -> LazyList a -> LazyList b
andMap =
  Lazy.List.andMap

-----------------------
-- PRIVATE FUNCTIONS --
-----------------------
seriesInt : Int -> Int -> LazyList Int
seriesInt low high =
  if | low >= high -> empty
     | low == high - 1 -> low ::: empty
     | otherwise ->
        let
            low' = low + ((high - low) // 2)
        in
            low ::: seriesInt low' high


seriesFloat : Float -> Float -> LazyList Float
seriesFloat low high =
  if low >= high - 0.0001
  then
    empty
  else
    let
        low' = low + ((high - low) / 2)
    in
        low ::: seriesFloat low' high
