module App.View where

import App.Model as App exposing (initialModel, Model)
import App.Update exposing (init, Action)

import Config.View exposing (view)
import Html exposing (a, div, h2, i, li, node, span, text, ul, button, Html)
import Html.Attributes exposing (class, classList, id, href, style, target, attribute)
import Html.Events exposing (onClick)

-- Pages import

import Pages.Article.View exposing (view)
import Pages.Event.View exposing (view)
import Pages.GithubAuth.View exposing (view)
import Pages.Login.View exposing (view)
import Pages.PageNotFound.View exposing (view)
import Pages.User.Model exposing (User)
import Pages.User.View exposing (view)

type alias Page = App.Page

isActivePage : Page -> Page -> Bool
isActivePage activePage page =
  case activePage of
    App.Event companyId ->
      page == (App.Event Nothing)
    _->
      activePage == page

view : Signal.Address Action -> Model -> Html
view address model =
  if model.configError == True
    then
      Config.View.view

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
    App.Article ->
      let
        childAddress =
          Signal.forwardTo address App.Update.ChildArticleAction
      in
        div [ style myStyle ] [ Pages.Article.View.view childAddress model.article ]

    App.Event companyId ->
      let
        childAddress =
          Signal.forwardTo address App.Update.ChildEventAction

        context =
          { companies = model.companies }
      in
        div [ style myStyle ] [ Pages.Event.View.view context childAddress model.events ]

    App.GithubAuth ->
      let
        childAddress =
          Signal.forwardTo address App.Update.ChildGithubAuthAction
      in
        div [ style myStyle ] [ Pages.GithubAuth.View.view childAddress model.githubAuth ]

    App.Login ->
      let
        childAddress =
          Signal.forwardTo address App.Update.ChildLoginAction

        context =
          { backendConfig = (.config >> .backendConfig) model }

      in
        div [ style myStyle ] [ Pages.Login.View.view context childAddress model.login ]

    App.PageNotFound ->
      div [] [ Pages.PageNotFound.View.view ]


    App.User ->
      let
        childAddress =
          Signal.forwardTo address App.Update.ChildUserAction
      in
        div [ style myStyle ] [ Pages.User.View.view childAddress model.user ]

navbar : Signal.Address Action -> Model -> Html
navbar address model =
  case model.user.name of
    Pages.User.Model.Anonymous ->
      div [] []

    Pages.User.Model.LoggedIn name ->
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
    activeClass page =
      [ ("active", isActivePage model.activePage page) ]

    childAddress =
      Signal.forwardTo address App.Update.ChildUserAction

    hrefVoid =
      href "javascript:void(0);"


    navCollapseButton =
      let
        iconBar index =
          span [ class "icon-bar" ] []

      in
        button
          [ class "navbar-toggle"
          , attribute "data-toggle" "collapse"
          , attribute "data-target" ".main-nav"
          ]
          [ span [ class "sr-only"] [ text "Menu" ]
          , span [] ( List.map iconBar [0..2] )
          ]

  in
    node "nav"
      [ id "main-header"
      , class "navbar navbar-default" ]
      [ div
          [ class "container" ]
          [ div
              [ class "navbar-header" ]
              [ a [ class "brand visible-xs pull-left", href "#!/" ] [ text "Hedley" ]
              , navCollapseButton
              ]
          , div
              [ class "collapse navbar-collapse main-nav" ]
              [ ul
                  [ class "nav navbar-nav"]
                  [ li [] [ a [ class "brand hidden-xs", href "#!/" ] [ text "Hedley" ] ]
                  , li
                      [ classList (activeClass App.User) ]
                      [ i [ class "glyphicon glyphicon-user" ] []
                      , a [ hrefVoid, onClick address (App.Update.SetActivePage App.User) ] [ text "My account" ]
                      ]
                  , li
                      [ classList (activeClass (App.Event Nothing)) ]
                      [ i [ class "fa fa-map-marker" ] []
                      , a [ hrefVoid, onClick address (App.Update.SetActivePage <| App.Event Nothing) ] [ text "Events" ]
                      ]
                  , li
                      [ classList (activeClass App.Article) ]
                      [ i [ class "fa fa-file-o" ] []
                      , a [ hrefVoid, onClick address (App.Update.SetActivePage App.Article) ] [ text "Articles"]
                      ]
                  , li
                      [  classList (activeClass App.PageNotFound) ]
                      [ i [ class "fa fa-exclamation-circle" ] []
                      , a [ href "#!/error-page" ] [ text "PageNotFound (404)" ]
                      ]
                  , li
                      []
                      [ i [ class "fa fa-sign-out" ] []
                      , a [ hrefVoid, onClick address App.Update.Logout ] [ text "Logout" ]
                      ]
                ]
              ]
          ]
      ]


myStyle : List (String, String)
myStyle =
  [ ("font-size", "1.2em") ]
