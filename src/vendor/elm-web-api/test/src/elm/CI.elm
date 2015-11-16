module Main where

import Signal exposing (Signal, Mailbox, mailbox, constant, send)
import Task exposing (Task, andThen, sequence)
import Graphics.Element exposing (Element, empty, flow, down, show)
import ElmTest.Runner.String exposing (runDisplay)
import Html exposing (Html, pre, text)
import Html.Attributes exposing (id)
import Tests


main : Signal Html
main =
    let
        update test result =
            (runDisplay test) :: result

        models =        
            Signal.foldp update [] (.signal Tests.tests)

        view model =
            pre [id "results"] <|
                List.map text model

    in
       Signal.map view models
        

port task : Task () ()
port task = Tests.task

