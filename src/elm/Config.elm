module Config where

import Config.Model as Config exposing (BackendConfig)
import Time exposing (Time)

localBackend : BackendConfig
localBackend =
  { backendUrl = "https://dev-hedley-elm.pantheon.io"
  , githubClientId = "e5661c832ed931ae176c"
  , name = "local"
  , hostname = "localhost"
  }

prodBackend : BackendConfig
prodBackend =
  { backendUrl = "https://live-hedley-elm.pantheon.io"
  , githubClientId = "4aef0ced83d72bd48d00"
  , name = "gh-pages"
  , hostname = "gizra.github.io"
  }

backends : List BackendConfig
backends =
  [ localBackend
  , prodBackend
  ]

cacheTtl : Time.Time
cacheTtl = (5 * Time.second)
