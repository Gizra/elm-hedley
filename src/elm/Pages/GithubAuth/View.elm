module Pages.GithubAuth.View where

-- import Config.Model exposing (BackendConfig)
-- import Dict exposing (get)
-- import Effects exposing (Effects)
import Html exposing (a, div, i, text, Html)
import Html.Attributes exposing (class, href, id)
-- import Http exposing (Error)
-- import Json.Decode as JD exposing ((:=))
-- import Json.Encode as JE exposing (..)
import Pages.GithubAuth.Model as GithubAuth exposing (initialModel, Model)
import Pages.GithubAuth.Update exposing (Action)


view : Signal.Address Action -> Model -> Html
view address model =
  let
    spinner =
      i [ class "fa fa-spinner fa-spin" ] []

    content =
      case model.status of
        GithubAuth.Error msg ->
          div []
            [text <| "Error:" ++ msg
            , a [ href "#!/login"] [text "Back to Login"]
            ]

        _ ->
          spinner

  in
    div
      [ id "github-auth-page" ]
      [ div [ class "container"] [ content ]
      ]
