module Config where

import Time exposing (Time)

backendUrl : String
backendUrl = "https://dev-hedley.pantheon.io"

cacheTtl : Time.Time
cacheTtl = (5 * Time.second)
