module App where

import ConfigManager exposing (Model)
import Company exposing (Model)
import Effects exposing (Effects)
import Event exposing (Model, initialModel, update)
import GithubAuth exposing (Model)
import Html exposing (a, div, h2, i, li, node, span, text, ul, Html)
import Html.Attributes exposing (class, href, style, target)
import Html.Events exposing (onClick)
import Json.Encode as JE exposing (string, Value)
import Login exposing (Model, initialModel, update)
import PageNotFound exposing (view)
import RouteHash exposing (HashUpdate)
import String exposing (isEmpty)
import Storage exposing (removeItem)
import Task exposing (..)
import User exposing (..)

import Debug

-- MODEL

type alias AccessToken = String
type alias CompanyId = Int

type Page
  = Event (Maybe CompanyId)
  | GithubAuth
  | Login
  | PageNotFound
  | User

type Status
  = Init
  | ConfigError

type alias Model =
  { accessToken : AccessToken
  , activePage : Page
  , config : ConfigManager.Model
  , companies : List Company.Model
  , events : Event.Model
  , githubAuth: GithubAuth.Model
  , login: Login.Model
  -- If the user is anonymous, we want to know where to redirect them.
  , nextPage : Maybe Page
  , status : Status
  , user : User.Model
  }

initialModel : Model
initialModel =
  { accessToken = ""
  , activePage = Login
  , config = ConfigManager.initialModel
  , companies = []
  , events = Event.initialModel
  , githubAuth = GithubAuth.initialModel
  , login = Login.initialModel
  , nextPage = Nothing
  , status = Init
  , user = User.initialModel
  }

initialEffects : List (Effects Action)
initialEffects =
  [ Effects.map ChildConfigAction <| snd ConfigManager.init
  , Effects.map ChildLoginAction <| snd Login.init
  ]

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.batch initialEffects
  )

-- UPDATE

type Action
  = ChildConfigAction ConfigManager.Action
  | ChildEventAction Event.Action
  | ChildGithubAuthAction GithubAuth.Action
  | ChildLoginAction Login.Action
  | ChildUserAction User.Action
  | Logout
  | SetAccessToken AccessToken
  | SetActivePage Page
  | SetStatus Status
  | UpdateCompanies (List Company.Model)

  -- NoOp actions
  | NoOp
  | NoOpLogout (Maybe ())
  | NoOpSetAccessToken (Result AccessToken ())


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    ChildConfigAction act ->
      let
        (childModel, childEffects) = ConfigManager.update act model.config

        status =
          case act of
            ConfigManager.SetStatus status ->
              if status == ConfigManager.Error
                then ConfigError
                else model.status

            _ ->
              model.status

      in
        ( {model
          | config <- childModel
          , status <- status
          }
        , Effects.map ChildConfigAction childEffects
        )

    ChildEventAction act ->
      let
        -- Pass the access token along to the child components.
        context =
          { accessToken = model.accessToken
          , backendConfig = (.config >> .backendConfig) model
          , companies = model.companies
          }

        (childModel, childEffects) = Event.update context act model.events
      in
        ( {model | events <- childModel }
        , Effects.map ChildEventAction childEffects
        )

    ChildGithubAuthAction act ->
      let

        context =
          { backendConfig = (.config >> .backendConfig) model }

        (childModel, childEffects) = GithubAuth.update context act model.githubAuth

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
            GithubAuth.SetAccessToken token ->
              (Task.succeed (SetAccessToken token) |> Effects.task)
              ::
              defaultEffects

            _ ->
              defaultEffects

      in
        ( {model | githubAuth <- childModel }
        , Effects.batch effects'
        )

    ChildLoginAction act ->
      let
        context =
          { backendConfig = (.config >> .backendConfig) model }

        (childModel, childEffects) = Login.update context act model.login

        defaultEffect =
          Effects.map ChildLoginAction childEffects

        -- A convinence variable to hold the default effect as a list.
        defaultEffects =
          [ defaultEffect ]

        effects' =
          case act of
            -- User's token was fetched, so we can set it in the accessToken
            -- root property, and also get the user info, which will in turn
            -- redirect the user from the login page.
            Login.SetAccessToken token ->
              (Task.succeed (SetAccessToken token) |> Effects.task)
              ::
              (Task.succeed (ChildUserAction User.GetDataFromServer) |> Effects.task)
              ::
              defaultEffects

            _ ->
              defaultEffects

      in
        ( {model | login <- childModel }
        , Effects.batch effects'
        )


    ChildUserAction act ->
      let
        context =
          { accessToken = model.accessToken
          , backendConfig = (.config >> .backendConfig) model
          }

        (childModel, childEffects) = User.update context act model.user

        defaultEffect =
          Effects.map ChildUserAction childEffects

        defaultEffects =
          [ defaultEffect ]

        model' =
          { model | user <- childModel }

        (model'', effects') =
          case act of
            -- Bubble up the SetAccessToken to the App level.
            User.SetAccessToken token ->
              ( model'
              , (Task.succeed (SetAccessToken token) |> Effects.task)
                ::
                defaultEffects
              )

            -- Act when user was successfully fetched from the server.
            User.UpdateDataFromServer result ->
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
                          Event Nothing

                  in
                    -- User data was successfully fetched, so we can redirect to
                    -- the next page, and update their companies.
                    ( { model' | nextPage <- Nothing }
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
      ( initialModel
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
              (Task.succeed (ChildUserAction User.GetDataFromServer) |> Effects.task)
              ::
              defaultEffects

      in
        ( { model | accessToken <- accessToken}
        , Effects.batch effects'
        )

    SetActivePage page ->
      let
        (page', nextPage) =
          if model.user.name == Anonymous
            then
              case page of
                GithubAuth ->
                  (GithubAuth, model.nextPage)

                -- The user is anonymous and we are asked to set the active page
                -- to login, then we make sure that the next page doesn't
                -- change, so they won't be rediected back to the login page.
                Login ->
                  (Login, model.nextPage)

                -- When the page is not found, we should keep the URL as is,
                -- and even after the user info was fetched, we should keep it
                -- so we set the next Page also to the error page.
                PageNotFound ->
                  (page, Just page)

                _ ->
                  (Login, Just page)

              -- Authenticated user.
              else (page, Nothing)

        currentPageEffects =
          case model.activePage of
            Event companyId ->
              Task.succeed (ChildEventAction Event.Deactivate) |> Effects.task

            _ ->
              Effects.none

        newPageEffects =
          case page' of
            Event companyId ->
              Task.succeed (ChildEventAction <| Event.Activate companyId) |> Effects.task

            GithubAuth ->
              Task.succeed (ChildGithubAuthAction GithubAuth.Activate) |> Effects.task

            _ ->
              Effects.none

      in
        if model.activePage == page'
          then
            -- Requesting the same page, so don't do anything.
            -- @todo: Because login and myAccount are under the same page (User)
            -- we set the nextPage here as-well.
            ( { model | nextPage <- nextPage }, Effects.none)
          else
            ( { model
              | activePage <- page'
              , nextPage <- nextPage
              }
            , Effects.batch
              [ currentPageEffects
              , newPageEffects
              ]
            )

    SetStatus status ->
      ( { model | status <- status}
      , Effects.none
      )

    UpdateCompanies companies ->
      ( { model | companies <- companies}
      , Effects.none
      )

    -- NoOp actions
    _ ->
      ( model, Effects.none )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  if model.status == ConfigError
    then
      div
      [ class "config-error"]
      [ h2 [] [ text "Configuration error" ]
      , div [] [ text "Check your Config.elm file and make sure you have defined the enviorement properly" ]
      ]
    else
      div
      []
      [ (navbar address model)
      , (mainContent address model)
      , footer
      ]

mainContent : Signal.Address Action -> Model -> Html
mainContent address model =
  case model.activePage of
    Event companyId ->
      let
        childAddress =
          Signal.forwardTo address ChildEventAction

        context =
          { companies = model.companies}
      in
        div [ style myStyle ] [ Event.view context childAddress model.events ]

    GithubAuth ->
      let
        childAddress =
          Signal.forwardTo address ChildGithubAuthAction
      in
        div [ style myStyle ] [ GithubAuth.view childAddress model.githubAuth ]

    Login ->
      let
        childAddress =
          Signal.forwardTo address ChildLoginAction

        context =
          { backendConfig = (.config >> .backendConfig) model }

      in
        div [ style myStyle ] [ Login.view context childAddress model.login ]

    PageNotFound ->
      div [] [ PageNotFound.view ]


    User ->
      let
        childAddress =
          Signal.forwardTo address ChildUserAction
      in
        div [ style myStyle ] [ User.view childAddress model.user ]

navbar : Signal.Address Action -> Model -> Html
navbar address model =
  case model.user.name of
    Anonymous ->
      div [] []

    LoggedIn name ->
      navbarLoggedIn address model

footer : Html
footer =

  div [class "main-footer"]
    [ div [class "container"]
      [ span []
        [ text "With "
        , i [ class "fa fa-heart" ] []
        , text " from "
        , a [ href "http://gizra.com", target "_blank", class "gizra-logo" ] [text "gizra"]
        , span [ class "divider" ] [text "|"]
        , text "Fork me on "
        , a [href "https://github.com/Gizra/elm-hedley", target "_blank"] [text "Github"]
        ]
      ]
  ]

-- Navbar for Auth user.
navbarLoggedIn : Signal.Address Action -> Model -> Html
navbarLoggedIn address model =
  let
    childAddress =
      Signal.forwardTo address ChildUserAction

    hrefVoid =
      href "javascript:void(0);"
  in
    node "nav" [class "navbar navbar-default"]
      [ div [class "container-fluid"]
        -- Brand and toggle get grouped for better mobile display
          [ div [class "navbar-header"] []
          , div [ class "collapse navbar-collapse"]
              [ ul [class "nav navbar-nav"]
                [ li [] [ a [ hrefVoid, onClick address (SetActivePage User) ] [ text "My account"] ]
                , li [] [ a [ hrefVoid, onClick address (SetActivePage <| Event Nothing)] [ text "Events"] ]
                , li [] [ a [ hrefVoid, onClick address Logout] [ text "Logout"] ]
                , li [] [ a [ href "#!/error-page"] [ text "PageNotFound (404)"] ]
                ]
              ]
          ]
      ]

myStyle : List (String, String)
myStyle =
  [ ("font-size", "1.2em") ]

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

-- ROUTING

delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
  case current.activePage of
    Event companyId ->
      -- First, we ask the submodule for a HashUpdate. Then, we use
      -- `map` to prepend something to the URL.
      RouteHash.map ((::) "events") <|
        Event.delta2update previous.events current.events

    GithubAuth ->
      RouteHash.map (\_ -> ["auth", "github"]) Nothing

    Login ->
      if current.login.hasAccessTokenInStorage
        -- The user has access token, but not yet logged in, so we don't change
        -- the url to "login", as we are just waiting for the server to fetch
        -- the user info.
        then Nothing
        else Just <| RouteHash.set ["login"]


    PageNotFound ->
      Nothing

    User ->
      Just <| RouteHash.set ["my-account"]


-- Here, we basically do the reverse of what delta2update does
location2action : List String -> List Action
location2action list =
  case list of
    ["auth", "github"] ->
      ( SetActivePage GithubAuth ) :: []

    "login" :: rest ->
      ( SetActivePage Login ) :: []

    "my-account" :: rest ->
      ( SetActivePage User ) :: []

    "events" :: rest ->
      ( SetActivePage <| Event (Event.location2company rest) ) :: []


    "" :: rest ->
      ( SetActivePage <| Event Nothing ) :: []

    _ ->
      ( SetActivePage PageNotFound ) :: []
