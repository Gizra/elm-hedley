module App.Router where

import App.Model as App exposing (Model)
import App.Update exposing (Action)
import Pages.Event.Router as Event exposing (delta2update, location2company)
import RouteHash exposing (HashUpdate)

type alias Model = App.Model

delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
  case current.activePage of
    App.Article ->
      Just <| RouteHash.set ["articles"]

    App.Event companyId ->
      -- First, we ask the submodule for a HashUpdate. Then, we use
      -- `map` to prepend something to the URL.
      RouteHash.map ((::) "events") <|
        Event.delta2update previous.events current.events

    App.GithubAuth ->
      RouteHash.map (\_ -> ["auth", "github"]) Nothing

    App.Login ->
      if current.login.hasAccessTokenInStorage
        -- The user has access token, but not yet logged in, so we don't change
        -- the url to "login", as we are just waiting for the server to fetch
        -- the user info.
        then Nothing
        else Just <| RouteHash.set ["login"]


    App.PageNotFound ->
      Nothing

    App.User ->
      Just <| RouteHash.set ["my-account"]


-- Here, we basically do the reverse of what delta2update does
location2action : List String -> List Action
location2action list =
  case list of
    ["auth", "github"] ->
      ( App.Update.SetActivePage App.GithubAuth ) :: []

    "articles" :: rest ->
      ( App.Update.SetActivePage App.Article ) :: []

    "login" :: rest ->
      ( App.Update.SetActivePage App.Login ) :: []

    "my-account" :: rest ->
      ( App.Update.SetActivePage App.User ) :: []

    "events" :: rest ->
      ( App.Update.SetActivePage <| App.Event (Event.location2company rest) ) :: []


    "" :: rest ->
      ( App.Update.SetActivePage <| App.Event Nothing ) :: []

    _ ->
      ( App.Update.SetActivePage App.PageNotFound ) :: []
