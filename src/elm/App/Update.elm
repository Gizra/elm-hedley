module App.Update where

import App.Model as App exposing (initialModel, Model)

import Config.Update exposing (init, Action)
import Company.Model as Company exposing (Model)
import Effects exposing (Effects)
import Json.Encode as JE exposing (string, Value)
import String exposing (isEmpty)
import Storage exposing (removeItem, setItem)
import Task exposing (succeed)

-- Pages import

import Pages.Article.Update exposing (Action)
import Pages.Event.Update exposing (Action)
import Pages.GithubAuth.Update exposing (Action)
import Pages.Login.Update exposing (Action)
import Pages.User.Model exposing (User)
import Pages.User.Update exposing (Action)

type alias AccessToken = String
type alias Model = App.Model

initialEffects : List (Effects Action)
initialEffects =
  [ Effects.map ChildConfigAction <| snd Config.Update.init
  , Effects.map ChildLoginAction <| snd Pages.Login.Update.init
  ]

init : (Model, Effects Action)
init =
  ( App.initialModel
  , Effects.batch initialEffects
  )

type Action
  = ChildArticleAction Pages.Article.Update.Action
  | ChildConfigAction Config.Update.Action
  | ChildEventAction Pages.Event.Update.Action
  | ChildGithubAuthAction Pages.GithubAuth.Update.Action
  | ChildLoginAction Pages.Login.Update.Action
  | ChildUserAction Pages.User.Update.Action
  | Logout
  | SetAccessToken AccessToken
  | SetActivePage App.Page
  | SetConfigError
  | UpdateCompanies (List Company.Model)

  -- NoOp actions
  | NoOp
  | NoOpLogout (Maybe ())
  | NoOpSetAccessToken (Result AccessToken ())


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    ChildArticleAction act ->
      let
        -- Pass the access token along to the child components.
        context =
          { accessToken = model.accessToken
          , backendConfig = (.config >> .backendConfig) model
          }

        (childModel, childEffects) = Pages.Article.Update.update context act model.article
      in
        ( {model | article = childModel }
        , Effects.map ChildArticleAction childEffects
        )

    ChildConfigAction act ->
      let
        (childModel, childEffects) = Config.Update.update act model.config

        defaultEffects =
          [ Effects.map ChildConfigAction childEffects ]

        effects' =
          case act of
            Config.Update.SetError ->
              -- Set configuration error.
              (Task.succeed SetConfigError |> Effects.task)
              ::
              defaultEffects
            _ ->
              defaultEffects

      in
        ( { model
          | config = childModel
          }
        , Effects.batch effects'
        )

    ChildEventAction act ->
      let
        -- Pass the access token along to the child components.
        context =
          { accessToken = model.accessToken
          , backendConfig = (.config >> .backendConfig) model
          , companies = model.companies
          }

        (childModel, childEffects) = Pages.Event.Update.update context act model.events
      in
        ( {model | events = childModel }
        , Effects.map ChildEventAction childEffects
        )

    ChildGithubAuthAction act ->
      let

        context =
          { backendConfig = (.config >> .backendConfig) model }

        (childModel, childEffects) = Pages.GithubAuth.Update.update context act model.githubAuth

        defaultEffect =
          Effects.map ChildGithubAuthAction childEffects

        -- A convinence variable to hold the default effect as a list.
        defaultEffects =
          [ defaultEffect ]

        effects' =
          case act of
            -- User's token was fetched, so we can set it in the accessToken
            -- root property, and also get the user info, which will in turn
            -- redirect the user from the login page.
            Pages.GithubAuth.Update.SetAccessToken token ->
              (Task.succeed (SetAccessToken token) |> Effects.task)
              ::
              defaultEffects

            _ ->
              defaultEffects

      in
        ( {model | githubAuth = childModel }
        , Effects.batch effects'
        )

    ChildLoginAction act ->
      let
        context =
          { backendConfig = (.config >> .backendConfig) model }

        (childModel, childEffects) = Pages.Login.Update.update context act model.login

        defaultEffect =
          Effects.map ChildLoginAction childEffects

        -- A convinence variable to hold the default effect as a list.
        defaultEffects =
          [ defaultEffect ]

        effects' =
          case act of
            -- -- User's token was fetched, so we can set it in the accessToken
            -- -- root property, and also get the user info, which will in turn
            -- -- redirect the user from the login page.
            Pages.Login.Update.SetAccessToken token ->
              (Task.succeed (SetAccessToken token) |> Effects.task)
              ::
              (Task.succeed (ChildUserAction Pages.User.Update.GetDataFromServer) |> Effects.task)
              ::
              defaultEffects

            _ ->
              defaultEffects

      in
        ( {model | login = childModel }
        , Effects.batch effects'
        )


    ChildUserAction act ->
      let
        context =
          { accessToken = model.accessToken
          , backendConfig = (.config >> .backendConfig) model
          }

        (childModel, childEffects) = Pages.User.Update.update context act model.user

        defaultEffect =
          Effects.map ChildUserAction childEffects

        defaultEffects =
          [ defaultEffect ]

        model' =
          { model | user = childModel }

        (model'', effects') =
          case act of
            -- Bubble up the SetAccessToken to the App level.
            Pages.User.Update.SetAccessToken token ->
              ( model'
              , (Task.succeed (SetAccessToken token) |> Effects.task)
                ::
                defaultEffects
              )

            -- Act when user was successfully fetched from the server.
            Pages.User.Update.UpdateDataFromServer result ->
              case result of
                -- We reach out into the companies that is passed to the child
                -- action.
                Ok (id, name, companies) ->
                  let
                    nextPage =
                      case model.nextPage of
                        Just page ->
                          page
                        Nothing ->
                          App.Event Nothing

                  in
                    -- User data was successfully fetched, so we can redirect to
                    -- the next page, and update their companies.
                    ( { model' | nextPage = Nothing }
                    , (Task.succeed (UpdateCompanies companies) |> Effects.task)
                      ::
                      (Task.succeed (SetActivePage nextPage) |> Effects.task)
                      ::
                      defaultEffects
                    )

                Err _ ->
                  ( model'
                  , defaultEffects
                  )

            _ ->
              ( model'
              , defaultEffects
              )

      in
        (model'', Effects.batch effects')

    Logout ->
      ( App.initialModel
      , Effects.batch <| removeStorageItem :: initialEffects
      )

    SetAccessToken accessToken ->
      let
        defaultEffects =
          [sendInputToStorage accessToken]

        effects' =
          if (String.isEmpty accessToken)
            then
              -- Setting an empty access token should result with a logout.
              (Task.succeed Logout |> Effects.task)
              ::
              defaultEffects
            else
              (Task.succeed (ChildUserAction Pages.User.Update.GetDataFromServer) |> Effects.task)
              ::
              defaultEffects

      in
        ( { model | accessToken = accessToken}
        , Effects.batch effects'
        )

    SetActivePage page ->
      let
        (page', nextPage) =
          if model.user.name == Pages.User.Model.Anonymous
            then
              case page of
                App.GithubAuth ->
                  (App.GithubAuth, model.nextPage)

                -- The user is anonymous and we are asked to set the active page
                -- to login, then we make sure that the next page doesn't
                -- change, so they won't be rediected back to the login page.
                App.Login ->
                  (App.Login, model.nextPage)

                -- When the page is not found, we should keep the URL as is,
                -- and even after the user info was fetched, we should keep it
                -- so we set the next Page also to the error page.
                App.PageNotFound ->
                  (page, Just page)

                _ ->
                  (App.Login, Just page)

              -- Authenticated user.
              else (page, Nothing)

        currentPageEffects =
          case model.activePage of
            App.Event companyId ->
              Task.succeed (ChildEventAction Pages.Event.Update.Deactivate) |> Effects.task

            _ ->
              Effects.none

        newPageEffects =
          case page' of
            App.Article ->
              Task.succeed (ChildArticleAction Pages.Article.Update.Activate) |> Effects.task

            App.Event companyId ->
              Task.succeed (ChildEventAction <| Pages.Event.Update.Activate companyId) |> Effects.task

            App.GithubAuth ->
              Task.succeed (ChildGithubAuthAction Pages.GithubAuth.Update.Activate) |> Effects.task

            _ ->
              Effects.none

      in
        if model.activePage == page'
          then
            -- Requesting the same page, so don't do anything.
            -- @todo: Because login and myAccount are under the same page (User)
            -- we set the nextPage here as-well.
            ( { model | nextPage = nextPage }, Effects.none)
          else
            ( { model
              | activePage = page'
              , nextPage = nextPage
              }
            , Effects.batch
              [ currentPageEffects
              , newPageEffects
              ]
            )

    SetConfigError ->
      ( { model | configError = True}
      , Effects.none
      )

    UpdateCompanies companies ->
      ( { model | companies = companies}
      , Effects.none
      )

    -- NoOp actions
    _ ->
      ( model, Effects.none )

-- EFFECTS

sendInputToStorage : String -> Effects Action
sendInputToStorage val =
  Storage.setItem "access_token" (JE.string val)
    |> Task.toResult
    |> Task.map NoOpSetAccessToken
    |> Effects.task

-- Task to remove the access token from localStorage.
removeStorageItem : Effects Action
removeStorageItem =
  Storage.removeItem "access_token"
    |> Task.toMaybe
    |> Task.map NoOpLogout
    |> Effects.task
