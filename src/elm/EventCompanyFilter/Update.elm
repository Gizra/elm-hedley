module EventCompanyFilter.Update where

import EventCompanyFilter.Model as EventCompanyFilter exposing (initialModel, Model)

import Company.Model as Company exposing (Model)
import Effects exposing (Effects)

init : (EventCompanyFilter.Model, Effects Action)
init =
  ( initialModel
  , Effects.none
  )


type Action
  = SelectCompany (Maybe Int)

type alias Context =
  { companies : List Company.Model
  }

type alias Model = EventCompanyFilter.Model

update : Context -> Action -> Model -> (Model, Effects Action)
update context action model =
  case action of
    SelectCompany maybeCompanyId ->
      let
        isValidCompany val =
          context.companies
            |> List.filter (\company -> company.id == val)
            |> List.length


        selectedCompany =
          case maybeCompanyId of
            Just val ->
              -- Make sure the given company ID is a valid one.
              if ((isValidCompany val) > 0)
                then Just val
                else Nothing
            Nothing ->
              Nothing
      in
        ( selectedCompany
        , Effects.none
        )
