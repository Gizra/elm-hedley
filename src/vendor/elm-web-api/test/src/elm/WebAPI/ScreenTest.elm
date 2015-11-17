module WebAPI.ScreenTest where

import ElmTest.Test exposing (..)
import ElmTest.Assertion exposing (..)
import Task exposing (Task, sequence, succeed, andThen)
import String

import WebAPI.Screen exposing (..)


screenTest : Task () Test
screenTest =
    screen |>
        Task.map (\s ->
            test "screen" <<
                assert <|
                    List.all ((flip (>=)) 0) <|
                        List.map ((|>) s)
                            [ .availTop
                            , .availLeft
                            , .availHeight
                            , .availWidth
                            , .colorDepth
                            , .pixelDepth
                            , .height
                            , .width
                            ]
        )


screenXYTest : Task () Test
screenXYTest =
    screenXY |>
        Task.map (\(x, y) ->
            test
                (String.join ""
                    [ "screenXY ("
                    , toString x, ", "
                    , toString y, ")"
                    ]
                ) <|
                -- Note that in IE, you get (-8, -8), which I suppose actually
                -- is meaningful.
                assert (x >= -32 && y >= -32)
        )


tests : Task () Test
tests =
    Task.map (suite "WebAPI.ScreenTest") <|
        sequence <|
            [ screenTest
            , screenXYTest
            ]

