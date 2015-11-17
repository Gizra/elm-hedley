module WebAPI.Number
    ( maxValue, minValue, nan, negativeInfinity, positiveInfinity
    , toExponential, toExponentialDigits, safeExponentialDigits
    , toFixed, toFixedDigits, safeFixedDigits
    , toPrecisionDigits, safePrecisionDigits
    , toStringUsingBase, safeStringUsingBase
    ) where


{-| Various facilities from the browser's `Number` object that are not
otherwise available in Elm.

See the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number).

## Constants

@docs maxValue, minValue, nan, negativeInfinity, positiveInfinity

## Functions

@docs toExponential, toExponentialDigits, safeExponentialDigits
@docs toFixed, toFixedDigits, safeFixedDigits
@docs toPrecisionDigits, safePrecisionDigits
@docs toStringUsingBase, safeStringUsingBase
-}


import Result exposing (Result)
import Debug
import Native.WebAPI.Number


{-| The largest positive representable number. -}
maxValue : Float
maxValue = Native.WebAPI.Number.maxValue


{-| The smallest positive representable number - that is, the positive number
closest to zero (without actually being zero).
-}
minValue : Float
minValue = Native.WebAPI.Number.minValue


{-| Special "not a number" value. -}
nan : Float
nan = Native.WebAPI.Number.nan


{-| Special value representing negative infinity; returned on overflow. -}
negativeInfinity : Float
negativeInfinity = Native.WebAPI.Number.negativeInfinity


{-| Special value representing infinity; returned on overflow. -}
positiveInfinity : Float
positiveInfinity = Native.WebAPI.Number.positiveInfinity


{-| A string representing the provided number in exponential notation. -}
toExponential : number -> String
toExponential = Native.WebAPI.Number.toExponential


{-| Either a string representing the second parameter in exponential notation,
with the requested number of digits after the decimal point (first parameter),
or an error. An error should not occur if the requested number of digits is
between 0 and 20.
-}
toExponentialDigits : Int -> number -> Result String String
toExponentialDigits = Native.WebAPI.Number.toExponentialDigits


{-| A string representing the second parameter in exponential notation,
with the requested number of digits after the decimal point (first parameter).
The number of digits will be limited to between 0 and 20.
-}
safeExponentialDigits : Int -> number -> String
safeExponentialDigits digits num =
    case toExponentialDigits (clamp 0 20 digits) num of
        Ok value ->
            value

        Err err ->
            Debug.crash "Unexpected error: " ++ err
    

{-| A string representing the provided number in fixed-point notation. -}
toFixed : number -> String
toFixed = Native.WebAPI.Number.toFixed


{-| Either a string representing the second parameter in fixed-point notation,
with the requested number of digits after the decimal point (first parameter),
or an error. An error should not occur if the requested number of digits is
between 0 and 20.

Note that Firefox returns `Ok 0` rather than an `Error` for a negative number
of requested digits.
-}
toFixedDigits : Int -> number -> Result String String
toFixedDigits = Native.WebAPI.Number.toFixedDigits


{-| A string representing the second parameter in fixed-point notation,
with the requested number of digits after the decimal point (first parameter).
The number of digits will be limited to between 0 and 20.
-}
safeFixedDigits : Int -> number -> String
safeFixedDigits digits num =
    case toFixedDigits (clamp 0 20 digits) num of
        Ok value ->
            value

        Err err ->
            Debug.crash "Unexpected error: " ++ err


{-| Either a string representing the second parameter in fixed-point or
exponential notation, with the requested number of significant digits (first
parameter), or an error. An error should not occur if the requested number of
digits is between 1 and 20.
-}
toPrecisionDigits : Int -> number -> Result String String
toPrecisionDigits = Native.WebAPI.Number.toPrecisionDigits


{-| A string representing the second parameter in fixed-point or exponential
notation, with the requested number of significant digits (first parameter).
The number of digits will be limited to between 1 and 20.
-}
safePrecisionDigits : Int -> number -> String
safePrecisionDigits digits num =
    case toPrecisionDigits (clamp 1 20 digits) num of
        Ok value ->
            value

        Err err ->
            Debug.crash "Unexpected error: " ++ err


{-| Either a string representing the second parameter, using the requested base
(first parameter), or an error. An error should not occur if the requested base
is between 2 and 36.
-}
toStringUsingBase : Int -> number -> Result String String
toStringUsingBase = Native.WebAPI.Number.toStringUsingBase


{-| A string representing the second parameter, using the requested base
(first parameter).  The requested base will be limited to between 2 and 36.
-}
safeStringUsingBase : Int -> number -> String
safeStringUsingBase base num =
    case toStringUsingBase (clamp 2 36 base) num of
        Ok value ->
            value

        Err err ->
            Debug.crash "Unexpected error: " ++ err
