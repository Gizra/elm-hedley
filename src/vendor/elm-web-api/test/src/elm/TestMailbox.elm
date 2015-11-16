module TestMailbox where

import Signal exposing (Signal, Mailbox, mailbox, constant, send)
import ElmTest.Test exposing (Test, suite)


tests : Mailbox Test
tests =
    mailbox (suite "Tests have not arrived yet" [])
