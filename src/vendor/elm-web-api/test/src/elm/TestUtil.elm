module TestUtil (sample) where


{-| Test utilities.

@docs sample
-}


import Task exposing (Task)
import Native.TestUtil


{-| Construct a task which, when performed, will return the current value of a Signal. -}
sample : Signal a -> Task x a
sample =
    Native.TestUtil.sample
