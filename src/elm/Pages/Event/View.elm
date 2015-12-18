module Pages.Event.View where

import Company.Model as Company exposing (Model)
import Event.Model exposing (Author, Event)
import EventAuthorFilter.View exposing (view)
import EventCompanyFilter.View exposing (view)
import Html exposing (a, div, input, text, select, span, li, option, ul, Html)
import Html.Attributes exposing (class, hidden, href, id, placeholder, selected, style, value)
import Html.Events exposing (on, onClick, targetValue)
import Pages.Event.Model exposing (initialModel, Model)
import Pages.Event.Update exposing (Action)
import String exposing (length)

type alias Action = Pages.Event.Update.Action
type alias CompanyId = Int
type alias Model = Pages.Event.Model.Model

type alias Context =
  { companies : List Company.Model }

view : Context -> Signal.Address Action -> Model -> Html
view context address model =
  let

    childEventAuthorFilterAddress =
      Signal.forwardTo address Pages.Event.Update.ChildEventAuthorFilterAction

    childEventCompanyFilterAddress =
      Signal.forwardTo address Pages.Event.Update.ChildEventCompanyFilterAction
  in
    div [class "container"]
      [ div [class "row"]
        [ div [class "col-md-3"]
            [ (EventCompanyFilter.View.view context.companies childEventCompanyFilterAddress model.eventCompanyFilter)
            , (EventAuthorFilter.View.view model.events childEventAuthorFilterAddress model.eventAuthorFilter)
            ]

        , div [class "col-md-9"]
            [ div [class "h2"] [ text "Map"]
            , div [ style mapStyle, id "map" ] []
            ]
        , div [] [ text (toString model)]
        ]
      ]


mapStyle : List (String, String)
mapStyle =
  [ ("width", "600px")
  , ("height", "400px")
  ]


isFetched : Pages.Event.Model.Status -> Bool
isFetched status =
  case status of
    Pages.Event.Model.Fetched _ _ -> True
    _ -> False
