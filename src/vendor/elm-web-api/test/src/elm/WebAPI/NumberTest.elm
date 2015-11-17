module WebAPI.NumberTest where

import ElmTest.Test exposing (..)
import ElmTest.Assertion exposing (..)
import Task exposing (Task, sequence, succeed)
import Result exposing (Result(..))

import WebAPI.Number


within : Float -> Float -> Float -> Assertion
within tolerance value1 value2 =
    assert <|
        abs (value1 - value2) < tolerance


within001 : Float -> Float -> Assertion
within001 = within 0.001


isErr : Result a b -> Bool
isErr result =
    case result of
        Ok _ -> False
        Err _ -> True


toFixedDigitsFailure : Test
toFixedDigitsFailure =
    let
        result =
            WebAPI.Number.toFixedDigits -10 200
            
    in
        -- Firefox gives 0 for this, which I suppose is somewhat sensible
        test ("toFixedDigits -10 200 should fail, or be 0: " ++ (toString result)) <|
            assert <|
                (isErr result) || result == (Ok "0") 


tests : Task x Test
tests =
    Task.map (suite "WebAPI.Number") <|
        sequence <|
            List.map succeed
                [ test "maxValue" <| assert <| WebAPI.Number.maxValue > 1000
                , test "minValue" <| within001 WebAPI.Number.minValue 0
                , test "nan" <| assert <| isNaN WebAPI.Number.nan
                , test "negativeInfinity" <| assert <| isInfinite WebAPI.Number.negativeInfinity
                , test "positiveInfinity" <| assert <| isInfinite WebAPI.Number.positiveInfinity
                , test "toExponential" <| assertEqual (WebAPI.Number.toExponential 200) "2e+2"
                , test "toExponentialDigits success" <| assertEqual (WebAPI.Number.toExponentialDigits 1 200.0) (Ok "2.0e+2")
                , test "toExponentialDigits failure" <| assert <| isErr (WebAPI.Number.toExponentialDigits -10 200)
                , test "toExponentialDigits integer" <| assertEqual (WebAPI.Number.toExponentialDigits 1 200) (Ok "2.0e+2")
                , test "safeExponentialDigits success" <| assertEqual (WebAPI.Number.safeExponentialDigits 1 200.0) "2.0e+2"
                , test "safeExponentialDigits failure" <| assertEqual (WebAPI.Number.safeExponentialDigits -10 200.0) "2e+2"
                , test "toFixed" <| assertEqual (WebAPI.Number.toFixed 200.1) "200"
                , test "toFixedDigits success" <| assertEqual (WebAPI.Number.toFixedDigits 2 200.1) (Ok "200.10")
                , toFixedDigitsFailure 
                , test "toFixedDigits integer" <| assertEqual (WebAPI.Number.toFixedDigits 2 200) (Ok "200.00")
                , test "safeFixedDigits success" <| assertEqual (WebAPI.Number.safeFixedDigits 2 200.1) "200.10"
                , test "safeFixedDigits failure" <| assertEqual (WebAPI.Number.safeFixedDigits -10 200.1) "200"
                , test "toPrecisionDigits success" <| assertEqual (WebAPI.Number.toPrecisionDigits 5 200.1) (Ok "200.10")
                , test "toPrecisionDigits failure" <| assert <| isErr (WebAPI.Number.toPrecisionDigits -10 200)
                , test "toPrecisionDigits integer" <| assertEqual (WebAPI.Number.toPrecisionDigits 2 223) (Ok "2.2e+2")
                , test "safePrecisionDigits success" <| assertEqual (WebAPI.Number.safePrecisionDigits 5 200.1) "200.10"
                , test "safePrecisionDigits failure" <| assertEqual (WebAPI.Number.safePrecisionDigits -10 200.1) "2e+2"
                , test "toStringUsingBase success" <| assertEqual (WebAPI.Number.toStringUsingBase 16 32.0) (Ok "20")
                , test "toStringUsingBase failure" <| assert <| isErr (WebAPI.Number.toStringUsingBase -10 200)
                , test "toStringUsingBase integer" <| assertEqual (WebAPI.Number.toStringUsingBase 16 32) (Ok "20")
                , test "safeStringUsingBase success" <| assertEqual (WebAPI.Number.safeStringUsingBase 16 32.0) "20"
                , test "safeStringUsingBase failure" <| assertEqual (WebAPI.Number.safeStringUsingBase -10 32) "100000"
                ]
