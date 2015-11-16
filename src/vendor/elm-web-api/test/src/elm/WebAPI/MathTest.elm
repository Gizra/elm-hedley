module WebAPI.MathTest where

import ElmTest.Test exposing (..)
import ElmTest.Assertion exposing (..)
import Task exposing (Task, sequence, succeed)

import WebAPI.Math


within : Float -> Float -> Float -> Assertion
within tolerance value1 value2 =
    assert <|
        abs (value1 - value2) < tolerance


within001 : Float -> Float -> Assertion
within001 = within 0.001


random : Task x Test
random =
    WebAPI.Math.random |>
        Task.map (\r ->
            test "random" <|
                assert <|
                    (r >= 0 && r <= 1)
        )


tests : Task x Test
tests =
    Task.map (suite "WebAPI.Math") <|
        sequence <|
            List.map succeed
                [ test "ln2" <| within001 WebAPI.Math.ln2 0.693
                , test "ln10" <| within001 WebAPI.Math.ln10 2.303
                , test "log2e" <| within001 WebAPI.Math.log2e 1.443
                , test "log10e" <| within001 WebAPI.Math.log10e 0.434
                , test "sqrt1_2" <| within001 WebAPI.Math.sqrt1_2 0.707
                , test "sqrt2" <| within001 WebAPI.Math.sqrt2 1.414
                , test "exp" <| within001 (WebAPI.Math.exp 2) (e ^ 2)
                , test "log" <| within001 (WebAPI.Math.log 27) (logBase e 27)
                ]
            ++
            [ random
            ]
