module Config.Model where

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

type alias Model =
  { backendConfig : BackendConfig
  , error : Bool
  }

initialModel : Model
initialModel =
  { backendConfig = initialBackendConfig
  , error = False
  }
