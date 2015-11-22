module Test.Console (runDisplay, display, isOk) where

import Check exposing (..)
import Check.Investigator exposing (..)

import IO.IO exposing (..)
import List
import Result

display : Evidence -> String
display evidence =
  case evidence of
    Unit unitEvidence ->
      displayUnit unitEvidence
    Multiple name evidences ->
      displaySuite name evidences

displaySuite : String -> List Evidence -> String
displaySuite name evidences =
  let
    displayList = List.map display evidences
    displays = List.foldr (++) "" displayList
  in
    "Suite: " ++ name ++ "\n" ++ displays ++ "\n"

displayUnit : UnitEvidence -> String
displayUnit unitEvidence =
  case unitEvidence of
    Ok options ->
      successMessage options
    Err options ->
      let
        checks = (toString options.numberOfChecks) ++ " check"++
                 (if options.numberOfChecks == 1 then "" else "s") ++ "\n"
      in
       options.name ++ " FAILED after " ++ checks  ++ "\n" ++
      "Counter example: " ++ options.counterExample ++ "\n" ++
      "Actual: " ++ options.actual ++ "\n" ++
      "Expected: " ++ options.expected ++ "\n"

successMessage : SuccessOptions -> String
successMessage {name, seed, numberOfChecks} =
  name ++ " passed after " ++ (toString numberOfChecks) ++ " checks. \n"

isOk : Evidence -> Bool
isOk evidence =
  case evidence of
    Unit (Ok _) ->
      True
    Unit (Err _) ->
      False
    Multiple _ evidences ->
      let
        oks = List.map isOk evidences
      in
        List.foldr (&&) True oks

runDisplay : Evidence -> IO ()
runDisplay evidence =
    let
      out = display evidence
    in putStrLn out >>>
       case isOk evidence of
            True  -> exit 0
            False -> exit 1
