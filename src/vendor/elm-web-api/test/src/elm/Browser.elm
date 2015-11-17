module Main where

import Signal exposing (Signal, Mailbox, mailbox, constant, send)
import Task exposing (Task, andThen, sequence)
import Graphics.Element exposing (Element, empty, flow, down)
import ElmTest.Runner.Element exposing (runDisplay)
import Tests


main : Signal Element
main =
    let
        update test element =
            flow down
                [ element
                , runDisplay test
                ]

    in
        Signal.foldp update empty (.signal Tests.tests)


port task : Task () ()
port task = Tests.task

