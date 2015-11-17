module WebAPI.Math 
    ( ln2, ln10, log2e, log10e, sqrt1_2, sqrt2
    , exp, log
    , random
    ) where


{-| Various facilities from the browser's `Math` object that are not
otherwise available in Elm.

See the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math).

## Constants

@docs ln2, ln10, log2e, log10e, sqrt1_2, sqrt2

## Functions

@docs exp, log

## Task

@docs random
-}


import Task exposing (Task)
import Native.WebAPI.Math


{-| Natural logarithm of 2, approximately 0.693. -}
ln2 : Float
ln2 = Native.WebAPI.Math.ln2


{-| Natural logarithm of 10, approximately 2.303. -}
ln10 : Float
ln10 = Native.WebAPI.Math.ln10


{-| Base 2 logarithm of E, approximately 1.443. -}
log2e : Float
log2e = Native.WebAPI.Math.log2e


{-| Base 10 logarithm of E, approximately 0.434 -}
log10e : Float
log10e = Native.WebAPI.Math.log10e


{-| Square root of 1/2; equivalently, 1 over the square root of 2,
approximately 0.707.
-}
sqrt1_2 : Float
sqrt1_2 = Native.WebAPI.Math.sqrt1_2


{-| Square root of 2, approximately 1.414. -}
sqrt2 : Float
sqrt2 = Native.WebAPI.Math.sqrt2


{-| Returns E to the power of x, where x is the argument, and E is Euler's
constant (2.718…), the base of the natural logarithm.
-}
exp : number -> Float
exp = Native.WebAPI.Math.exp


{-| Returns the natural logarithm (loge, also ln) of a number. -}
log : number -> Float
log = Native.WebAPI.Math.log


{-| Returns a pseudo-random number between 0 and 1.

Note that there is a more sophisticated implementation of `Random` in
elm-lang/core. However, this may sometimes be useful if you're in a `Task`
context anyway.
-}
random : Task x Float
random = Native.WebAPI.Math.random

