module Pages.User.View where

import Company exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import String

import Pages.User.Model as User exposing (..)
import Pages.User.Update exposing (..)

import Debug

view : Signal.Address Action -> User.Model -> Html
view address model =
  case model.name of
    Anonymous ->
      div [] [ text "This is wrong - anon user cannot reach this!"]

    LoggedIn name ->
      let
        mainTitle =
          h3
          [ class "title" ]
          [ i [ class "glyphicon glyphicon-user" ] []
          , text " My account"
          ]
      in
        div
          [
          id "my-account"
          , class "container"
          ]
          [ div
              [ class "wrapper -suffix"]
              [ mainTitle
              , h4 [ class "name" ] [ text <| "Welcome " ++ name ]
              , h4 [ class "company-title"] [ text "Your companies are:" ]
              , ul  [ class "companies" ] (List.map viewCompanies model.companies)
              ]
          ]


viewCompanies : Company.Model -> Html
viewCompanies company =
  li [] [ text company.label ]
