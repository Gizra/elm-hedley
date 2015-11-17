module ConfigType where

type alias BackendConfig =
  { backendUrl : String
  , githubClientId : String
  , name : String
  -- Url information
  , hostname : String
  }

initialBackendConfig : BackendConfig
initialBackendConfig =
  { backendUrl = ""
  , githubClientId = ""
  , name = ""
  , hostname = ""
  }
