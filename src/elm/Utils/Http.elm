module Utils.Http where

import Http exposing (Error)

getErrorMessageFromHttpResponse : Http.Error -> String
getErrorMessageFromHttpResponse err =
  case err of
    Http.Timeout ->
      "Connection has timed out"

    Http.BadResponse code _ ->
      if | code == 401 -> "Wrong username or password"
         | code == 429 -> "Too many login requests with the wrong username or password. Wait a few hours before trying again"
         | code >= 500 -> "Some error has occured on the server"
         | otherwise -> "Unknow error has occured"

    Http.NetworkError ->
      "A network error has occured"

    Http.UnexpectedPayload string ->
      "Unknow error has occured: " ++ string
