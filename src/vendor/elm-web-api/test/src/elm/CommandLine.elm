module Main where

import Task exposing (Task)
import Tests
import ElmTest.Test exposing (Test)
import ElmTest.Runner.String exposing (runDisplay)


test : Task () Test
test = Tests.test


port task : Task () ()
port task =
    Task.map runDisplay test
        `Task.andThen` Signal.send results.address
        
        
results : Signal.Mailbox String
results = Signal.mailbox ""


port result : Signal String
port result =
    results.signal


