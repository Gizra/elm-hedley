module Config where

import Time exposing (Time)

backendUrl : String
backendUrl = "http://localhost/hedley-server/www"

cacheTtl : Time.Time
cacheTtl = (5 * Time.second)

githubClientId : String
githubClientId = "e5661c832ed931ae176c"
