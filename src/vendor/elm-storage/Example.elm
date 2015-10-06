import Storage exposing (..)

import Html exposing (text, div, input, form)
import Html.Attributes exposing (type')
import Html.Events exposing (on, targetValue)
import Json.Encode exposing (string, Value)
import Json.Decode as Decode

import Signal exposing (Signal, Mailbox, Message, mailbox, message, send)
import Task exposing (Task, succeed, andThen, mapError, onError, fail)

sendInputMailbox : Mailbox (Task String ())
sendInputMailbox = mailbox (succeed ())

currentValueMailbox : Mailbox String
currentValueMailbox = mailbox ""

sendInputToStorage : String -> Task String ()
sendInputToStorage =
  setItem "Test" << string

getInputFromStorage : Task String String
getInputFromStorage =
  getItem "Test" Decode.string


sendInput : String -> Task String ()
sendInput value = sendInputToStorage value
  `andThen` \_ -> getInputFromStorage
  `andThen` \val -> send currentValueMailbox.address val



view model =
  div []
  [ input
    [ on "input" targetValue (message sendInputMailbox.address << sendInput)
    ] []
  , text model
  ]


port sendInputPort : Signal (Task String ())
port sendInputPort =
  sendInputMailbox.signal



main = Signal.map view currentValueMailbox.signal
