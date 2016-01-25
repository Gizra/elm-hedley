module Pages.Event.View where

import Company.Model as Company exposing (Model)
import EventAuthorFilter.View exposing (view)
import EventCompanyFilter.View exposing (view)
import EventList.View exposing (view)
import Html exposing (h3, a, i, div, input, text, select, span, li, option, ul, Html)
import Html.Attributes exposing (class, hidden, href, id, placeholder, selected, style, value)
import Pages.Event.Model exposing (initialModel, Model)
import Pages.Event.Update exposing (Action)
import Pages.Event.Utils exposing (filterEventsByAuthor)

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

    childEventListAddress =
        Signal.forwardTo address Pages.Event.Update.ChildEventListAction

    filteredEvents =
      filterEventsByAuthor model.events model.eventAuthorFilter

  in
    div
      [ id "events-page"
      , class "container"
      ]
      [ div [class "row"]
        [ div [class "col-md-3 first"]
            [ (EventCompanyFilter.View.view context.companies childEventCompanyFilterAddress model.eventCompanyFilter)
            , (EventAuthorFilter.View.view model.events childEventAuthorFilterAddress model.eventAuthorFilter)
            , (EventList.View.view filteredEvents childEventListAddress model.eventList)
            ]

        , div
            [ class "col-md-9 last"]
            [ div
              [ class "map-container wrapper -suffix" ]
              [ h3
                  [ class "title" ]
                  [ i [ class "fa fa-globe" ] []
                  , text <| " " ++ "Map"
                  ]
              , div
                  [ class "map-wrapper" ]
                  [ div [ id "map"] [] ]
              ]
            ]
        ]
      ]
