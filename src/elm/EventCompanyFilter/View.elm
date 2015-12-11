module EventCompanyFilter.View where

import EventCompanyFilter.Model as EventCompanyFilter exposing (initialModel, Model)
import EventCompanyFilter.Update exposing (Action)

-- import Config exposing (cacheTtl)
-- import ConfigType exposing (BackendConfig)
import Company.Model as Company exposing (Model)
-- import Dict exposing (Dict)
-- import Effects exposing (Effects)
-- import Html exposing (a, div, input, text, select, span, li, option, ul, Html)
-- import Html.Attributes exposing (class, hidden, href, id, placeholder, selected, style, value)
-- import Html.Events exposing (on, onClick, targetValue)
-- import Http
-- import Json.Decode as Json exposing ((:=))
-- import Leaflet exposing (Model, initialModel, Marker, update)
-- import RouteHash exposing (HashUpdate)
-- import String exposing (length)
-- import Task  exposing (andThen, Task)
-- import TaskTutorial exposing (getCurrentTime)
-- import Time exposing (Time)

type alias Context =
  { companies : List Company.Model }

view : Context -> Signal.Address Action -> Model -> Html
view context address model =
  div
    []
    [ div [class "h2"] [ text "Companies"]
    , companyListForSelect address context.companies model
    ]

companyListForSelect : Signal.Address Action -> List Company.Model -> Model -> Html
companyListForSelect address companies selectedCompany  =
  let
    selectedText =
      case selectedCompany of
        Just id -> toString id
        Nothing -> ""

    textToMaybe string =
      if string == "0"
        then Nothing
        else
          -- Converting to int return a result.
          case (String.toInt string) of
            Ok val ->
              Just val
            Err _ ->
              Nothing


    -- Add an "All companies" option
    companies' =
      (Company.Model 0 "-- All companies --") :: companies

    -- The selected company ID.
    selectedId =
      case selectedCompany of
        Just id ->
          id
        Nothing ->
          0

    getOption company =
      option [value <| toString company.id, selected (company.id == selectedId)] [ text company.label]
  in
    select
      [ value selectedText
      , on "change" targetValue (\str -> Signal.message address <| SelectCompany <| textToMaybe str)
      ]
      (List.map getOption companies')
