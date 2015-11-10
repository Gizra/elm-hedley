module App where


import Company exposing (Model)
import Effects exposing (Effects)
import Event exposing (Model, initialModel, update)
import Html exposing (a, div, i, li, node, span, text, ul, Html)
import Html.Attributes exposing (class, href, style, target)
import Html.Events exposing (onClick)
import Login exposing (Model, initialModel, update)
import PageNotFound exposing (view)
import RouteHash exposing (HashUpdate)
import Storage exposing (removeItem)
import Task exposing (..)
import User exposing (..)

import Debug

-- MODEL

type alias AccessToken = String
type alias CompanyId = Int

type Page
  = Event (Maybe CompanyId)
  | Login
  | PageNotFound
  | User

type alias Model =
  { accessToken : AccessToken
  , user : User.Model
  , companies : List Company.Model
  , events : Event.Model
  , login: Login.Model
  , activePage : Page
  -- If the user is anonymous, we want to know where to redirect them.
  , nextPage : Maybe Page
  }

initialModel : Model
initialModel =
  { accessToken = ""
  , user = User.initialModel
  , companies = []
  , events = Event.initialModel
  , login = Login.initialModel
  , activePage = Login
  , nextPage = Nothing
  }

initialEffects : List (Effects Action)
initialEffects =
  [ Effects.map ChildLoginAction <| snd Login.init ]

init : (Model, Effects Action)
init =
  ( initialModel
  , Effects.batch initialEffects
  )

-- UPDATE

type Action
  = ChildEventAction Event.Action
  | ChildLoginAction Login.Action
  | ChildUserAction User.Action
  | Logout
  -- Action to be called after a Logout
  | NoOp (Maybe ())
  | SetAccessToken AccessToken
  | SetActivePage Page
  | UpdateCompanies (List Company.Model)

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    ChildEventAction act ->
      let
        -- Pass the access token along to the child components.
        context =
          { accessToken = model.accessToken }

        (childModel, childEffects) = Event.update context act model.events
      in
        ( {model | events <- childModel }
        , Effects.map ChildEventAction childEffects
        )

    ChildLoginAction act ->
      let

        (childModel, childEffects) = Login.update act model.login

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
          { accessToken = model.accessToken }

        (childModel, childEffects) = User.update context act model.user

        defaultEffect =
          Effects.map ChildUserAction childEffects

        defaultEffects =
          [ defaultEffect ]

        model' =
          { model | user <- childModel }

        (model'', effects') =
          case act of
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

    NoOp _ ->
      ( model, Effects.none )

    SetAccessToken accessToken ->
      ( { model | accessToken <- accessToken}
      , Task.succeed (ChildUserAction User.GetDataFromServer) |> Effects.task
      )

    SetActivePage page ->
      let
        (page', nextPage) =
          if model.user.name == Anonymous
            then
              case page of
                -- When the page is not found, we should keep the URL as is,
                -- and even after the user info was fetched, we should keep it
                -- so we set the next Page also to the error page.
                PageNotFound ->
                  (page, Just page)

                -- The user is anonymous and we are asked to set the active page
                -- to login, then we make sure that the next page doesn't
                -- change, so they won't be rediected back to the login page.
                Login ->
                  (Login, model.nextPage)

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
              Task.succeed (ChildEventAction <| Event.Activate Nothing) |> Effects.task

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

    UpdateCompanies companies ->
      ( { model | companies <- companies}
      , Effects.none
      )

-- Task to remove the access token from localStorage.
removeStorageItem : Effects Action
removeStorageItem =
  Storage.removeItem "access_token"
    |> Task.toMaybe
    |> Task.map NoOp
    |> Effects.task

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  div []
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

    Login ->
      let
        childAddress =
          Signal.forwardTo address ChildLoginAction
      in
        div [ style myStyle ] [ Login.view childAddress model.login ]

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
                , li [] [ a [ href "/#!/error-page"] [ text "PageNotFound (404)"] ]
                ]
              ]
          ]
      ]

myStyle : List (String, String)
myStyle =
  [ ("font-size", "1.2em") ]


-- ROUTING

delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
  case current.activePage of
    Event companyId ->
      -- First, we ask the submodule for a HashUpdate. Then, we use
      -- `map` to prepend something to the URL.
      RouteHash.map ((::) "events") <|
        Event.delta2update previous.events current.events

    Login ->
      if current.login.hasAccessTokenInStorage
        -- The user has access token, but not yet logged in, so we don't change
        -- the url to "login", as we are just waiting for the server to fetch
        -- the user info.
        then Nothing
        else RouteHash.map ((::) "login") <| Login.delta2update previous.login current.login


    PageNotFound ->
      Nothing

    User ->
      RouteHash.map ((::) "my-account") <|
        User.delta2update previous.user current.user


-- Here, we basically do the reverse of what delta2update does
location2action : List String -> List Action
location2action list =
  case list of
    "login" :: rest ->
      ( SetActivePage Login ) :: []

    "my-account" :: rest ->
      ( SetActivePage User ) :: []

    "events" :: rest ->
      ( SetActivePage <| Event Nothing ) :: []

    "" :: rest ->
      ( SetActivePage <| Event Nothing ) :: []

    _ ->
      ( SetActivePage PageNotFound ) :: []
