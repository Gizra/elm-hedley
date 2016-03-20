module Utils.Http where

import Http exposing (Error)

getErrorMessageFromHttpResponse : Http.Error -> String
getErrorMessageFromHttpResponse err =
  case err of
    Http.Timeout ->
      "Connection has timed out"

    Http.BadResponse code _ ->
      if code == 401 then
        "Wrong username or password"
      else if code == 429 then
        "Too many login requests with the wrong username or password. Wait a few hours before trying again"
      else
        "Some error has occurred on the server"

    Http.NetworkError ->
      "A network error has occurred"

    Http.UnexpectedPayload string ->
      "Unknown error has occurred: " ++ string
