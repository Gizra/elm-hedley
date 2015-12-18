module Pages.Event.Update where

import Config exposing (cacheTtl)
import Config.Model exposing (BackendConfig)
import Company.Model as Company exposing (Model)
import Effects exposing (Effects)
import Event.Decoder exposing (decode)
import Event.Model exposing (Event)
import EventAuthorFilter.Update exposing (Action)
import EventCompanyFilter.Update exposing (Action)
import EventList.Update exposing (Action)
import Http exposing (Error)
import Leaflet.Model exposing (initialModel, Marker)
import Leaflet.Update exposing (Action)
import Pages.Event.Model as Event exposing (Model)
import String exposing (length, trim)
import Task  exposing (andThen, succeed)
import TaskTutorial exposing (getCurrentTime)
import Time exposing (Time)

type alias Id = Int
type alias CompanyId = Int
type alias Model = Event.Model

init : (Model, Effects Action)
init =
  ( Event.initialModel
  , Effects.none
  )

type Action
  = NoOp
  | GetData (Maybe CompanyId)
  | GetDataFromServer (Maybe CompanyId)
  | UpdateDataFromServer (Result Http.Error (List Event)) (Maybe CompanyId) Time.Time

  -- Child actions
  | ChildEventAuthorFilterAction EventAuthorFilter.Update.Action
  | ChildEventCompanyFilterAction EventCompanyFilter.Update.Action
  | ChildEventListAction EventList.Update.Action
  | ChildLeafletAction Leaflet.Update.Action

  -- Page
  | Activate (Maybe CompanyId)
  | Deactivate


type alias Context =
  { accessToken : String
  , backendConfig : BackendConfig
  , companies : List Company.Model
  }

update : Context -> Action -> Model -> (Model, Effects Action)
update context action model =
  case action of
    ChildEventAuthorFilterAction act ->
      let
        -- The child component doesn't have effects.
        childModel =
          EventAuthorFilter.Update.update act model.selectedAuthor
      in
        ( { model | selectedAuthor = childModel }
        , Effects.none
        )

    ChildEventCompanyFilterAction act ->
      -- Reach into the selected company, and invoke getting the data.
      case act of
        EventCompanyFilter.Update.SelectCompany maybeCompanyId ->
          ( model
          , Task.succeed (GetData maybeCompanyId) |> Effects.task
          )

    ChildEventListAction act ->
      (model, Effects.none)

    GetData maybeCompanyId ->
      let
        noFx =
          (model, Effects.none)

        getFx =
          (model, getDataFromCache model.status maybeCompanyId)
      in
      case model.status of
        Event.Fetching id ->
          if id == maybeCompanyId
            -- We are already fetching this data
            then noFx
            -- We are fetching data, but for a different company ID,
            -- so we need to re-fetch.
            else getFx

        _ ->
          getFx

    GetDataFromServer maybeCompanyId ->
      let
        backendUrl =
          (.backendConfig >> .backendUrl) context

        url =
          backendUrl ++ "/api/v1.0/events"
      in
        ( { model | status = Event.Fetching maybeCompanyId}
        , getJson url maybeCompanyId context.accessToken
        )

    NoOp ->
      (model, Effects.none)

    UpdateDataFromServer result maybeCompanyId timestamp ->
      case result of
        Ok events ->
          ( {model
            | events = events
            , status = Event.Fetched maybeCompanyId timestamp
            }
          -- , Task.succeed (FilterEvents model.filterString) |> Effects.task
          , Effects.none
          )

        Err msg ->
          ( {model | status = Event.HttpError msg}
          , Effects.none
          )

    ChildLeafletAction act ->
      let
        (childModel, childEffects) = Leaflet.Update.update act model.leaflet
      in
        ( {model | leaflet = childModel }
        , Effects.map ChildLeafletAction childEffects
        )

    Activate maybeCompanyId ->
      let
        (childModel, childEffects) =
          Leaflet.Update.update Leaflet.Update.ToggleMap model.leaflet

      in
        ( { model | leaflet = childModel }
        , Effects.batch
            -- Get data without companies filtering.
            [ Task.succeed (GetData Nothing) |> Effects.task
            , Effects.map ChildLeafletAction childEffects
            ]
        )

    Deactivate ->
      let
        (childModel, childEffects) = Leaflet.Update.update Leaflet.Update.ToggleMap model.leaflet
      in
        ( {model | leaflet = childModel }
        , Effects.map ChildLeafletAction childEffects
        )


-- EFFECTS

getDataFromCache : Event.Status -> Maybe CompanyId -> Effects Action
getDataFromCache status maybeCompanyId =
  let
    getFx =
      Task.succeed <| GetDataFromServer maybeCompanyId

    actionTask =
      case status of
        Event.Fetched id fetchTime ->
          if id == maybeCompanyId
            then
              Task.map (\currentTime ->
                if fetchTime + Config.cacheTtl > currentTime
                  then NoOp
                  else GetDataFromServer maybeCompanyId
              ) getCurrentTime
            else
              getFx

        _ ->
          getFx

  in
    Effects.task actionTask


getJson : String -> Maybe CompanyId -> String -> Effects Action
getJson url maybeCompanyId accessToken =
  let
    params =
      [ ("access_token", accessToken) ]

    params' =
      case maybeCompanyId of
        Just id ->
          -- Filter by company
          ("filter[company]", toString id) :: params

        Nothing ->
          params


    encodedUrl =
      Http.url url params'

    httpTask =
      Task.toResult <|
        Http.get Event.Decoder.decode encodedUrl

    actionTask =
      httpTask `andThen` (\result ->
        Task.map (\timestamp ->
          UpdateDataFromServer result maybeCompanyId timestamp
        ) getCurrentTime
      )

  in
    Effects.task actionTask
