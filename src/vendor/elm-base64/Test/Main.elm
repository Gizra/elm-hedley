module Main where

import Test.AsciiTest as AsciiTest
import Test.Base64Test as Base64Test
import Test.BitListTest as BitListTest
import Test.Base64Check as Base64Check
import IO.IO exposing (putStrLn, exit,(>>>))
import IO.Runner exposing (Request, Response, run)
import ElmTest.Run as Run
import ElmTest.Test as Test
import ElmTest.Test exposing (Test)
import Test.Console as CheckConsole
import Check
import ElmTest.Runner.String as TestString
import String

allTests : Test
allTests = Test.suite "Main" [
  BitListTest.tests,
  Base64Test.tests,
  AsciiTest.tests
  ]

allChecks : Check.Claim
allChecks =
  Check.suite "Main"
    [ Base64Check.checks ]

runTests : Test -> (String, Bool)
runTests tests =
  let
    ((summary, allPassed) :: results) = TestString.run tests
    out = summary ++ "\n\n" ++ (String.concat << List.intersperse "\n" << List.map fst <| results)
  in
    (out, Run.pass allPassed)


runChecks : Check.Claim -> (String, Bool)
runChecks evidence =
  let
    evidence = Check.quickCheck allChecks
    out = CheckConsole.display evidence
    allPassed = CheckConsole.isOk evidence
  in
    (out, allPassed)

port requests : Signal Request
port requests =
  let
    (testsOut, testsOk)  = runTests allTests
    (checksOut, checksOk) = runChecks allChecks
    out = (testsOut ++ checksOut)
    exitCode = if (testsOk && checksOk) then 0 else 1
  in
    run responses (
      putStrLn out >>> exit exitCode
    )

port responses : Signal Response
