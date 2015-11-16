module WebAPI.AnimationFrameTest where

import ElmTest.Test exposing (..)
import ElmTest.Assertion exposing (..)
import Task exposing (Task, sequence, succeed, andThen)
import Time exposing (Time)
import Signal exposing (Signal, Mailbox, mailbox)
import String

import WebAPI.AnimationFrame as AnimationFrame
import WebAPI.Date
import Debug
import TestUtil exposing (sample)


-- When testing on SauceLabs, this is really slow ... much faster locally ...
-- not sure why. So, we allow an absurd amount of time for a frame here ...
-- when run locally, the frame rate is about right. So, this is not really
-- testing performance at the moment, just that it works at all.
frame : Time
frame = Time.second


taskTest : Task () Test
taskTest =
    WebAPI.Date.now `andThen` (\startTime ->
    AnimationFrame.task `andThen` (\timestamp ->
    AnimationFrame.task `andThen` (\timestamp2 ->
    WebAPI.Date.now `andThen` (\endTime ->
        let
            wallTime =
                endTime - startTime

            delta =
                timestamp2 - timestamp

        in
            Task.succeed <|
                suite "task"
                    [ test
                        ( String.join " "
                            [ "wall time"
                            , toString wallTime
                            , "is less than"
                            , toString (frame * 2)
                            ]
                        ) <|
                        assert (wallTime < frame * 2)
                    , test
                        ( String.join " "
                            [ "callback time"
                            , toString delta 
                            , "is less than"
                            , toString frame
                            ]
                        ) <|
                        assert (delta < frame)
                    ]
    ))))


result : Mailbox Time
result = mailbox 0


delay : Time
delay = 0.2 * Time.second


requestTest : Task () Test
requestTest =
    let
        task time =
            Signal.send result.address time

    in
        Task.map (\time ->
            test ("request fired at " ++ (toString time)) <|
                assert (time > 0)
        ) <| Signal.send result.address 0
            `andThen` always (AnimationFrame.request task)
            `andThen` always (Task.sleep delay)
            `andThen` always (sample result.signal)


cancelTest : Task () Test
cancelTest =
    let
        task time =
            Signal.send result.address time

    in
        Task.map (\time -> 
            test "request should have been canceled" <|
                assertEqual 0 time
        ) <| Signal.send result.address 0
            `andThen` always (AnimationFrame.request task)
            `andThen` AnimationFrame.cancel
            `andThen` always (Task.sleep delay) 
            `andThen` always (sample result.signal)


tests : Task () Test
tests =
    Task.map (suite "WebAPI.AnimationFrameTest") <|
        sequence <|
            [ taskTest
            , requestTest
            , cancelTest
            ]

