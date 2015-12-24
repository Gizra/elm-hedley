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
import EventList.Utils exposing (filterEventsByString)
import Http exposing (Error)
import Leaflet.Update exposing (Action)
import Pages.Event.Model as Event exposing (Model)
import Pages.Event.Utils exposing (filterEventsByAuthor)
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
          EventAuthorFilter.Update.update act model.eventAuthorFilter
      in
        ( { model | eventAuthorFilter = childModel }
        -- Filter out the events, before sending the events' markers.
        , Task.succeed (ChildLeafletAction <| Leaflet.Update.SetMarkers (filterEventsByAuthor model.events childModel)) |> Effects.task
        )

    ChildEventCompanyFilterAction act ->
      let
        childModel =
          EventCompanyFilter.Update.update context.companies act model.eventCompanyFilter

        maybeCompanyId =
          -- Reach into the selected company, in order to invoke getting the
          -- data from server.
          case act of
            EventCompanyFilter.Update.SelectCompany maybeCompanyId ->
              maybeCompanyId

      in
        ( { model | eventCompanyFilter = childModel }
        , Task.succeed (GetData maybeCompanyId) |> Effects.task
        )

    ChildEventListAction act ->
      let
        filteredEventsByAuthor =
          filterEventsByAuthor model.events model.eventAuthorFilter

        -- The child component doesn't have effects.
        childModel =
          EventList.Update.update filteredEventsByAuthor act model.eventList

        childAction =
          case act of
            EventList.Update.FilterEvents val ->
              -- Filter out the events, before sending the events' markers.
              Leaflet.Update.SetMarkers (filterEventsByString filteredEventsByAuthor val)

            EventList.Update.SelectEvent val ->
              Leaflet.Update.SelectMarker val

            EventList.Update.UnSelectEvent ->
              Leaflet.Update.UnselectMarker
      in
        ( { model | eventList = childModel }
        , Task.succeed (ChildLeafletAction <| childAction) |> Effects.task
        )

    ChildLeafletAction act ->
      let
        childModel =
          Leaflet.Update.update act model.leaflet
      in
        ( {model | leaflet = childModel }
        , Effects.none
        )

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
        ( { model | status = Event.Fetching maybeCompanyId }
        , getJson url maybeCompanyId context.accessToken
        )

    NoOp ->
      (model, Effects.none)

    UpdateDataFromServer result maybeCompanyId timestamp ->
      case result of
        Ok events ->
          let
            filteredEventsByAuthor =
              filterEventsByAuthor events model.eventAuthorFilter

            filteredEvents =
              filterEventsByString filteredEventsByAuthor model.eventList.filterString
          in
            ( { model
              | events = events
              , status = Event.Fetched maybeCompanyId timestamp
              }
            , Effects.batch
              [ Task.succeed (ChildEventAuthorFilterAction EventAuthorFilter.Update.UnSelectAuthor) |> Effects.task
              , Task.succeed (ChildEventListAction EventList.Update.UnSelectEvent) |> Effects.task
              , Task.succeed (ChildEventListAction <| EventList.Update.FilterEvents "") |> Effects.task
              ]
            )

        Err msg ->
          ( { model | status = Event.HttpError msg }
          , Effects.none
          )

    Activate maybeCompanyId ->
      let
        childModel =
          Leaflet.Update.update Leaflet.Update.ToggleMap model.leaflet

      in
        ( { model | leaflet = childModel }
        , Effects.batch
          [ Task.succeed (GetData maybeCompanyId) |> Effects.task
          , Task.succeed (ChildEventCompanyFilterAction <| EventCompanyFilter.Update.SelectCompany maybeCompanyId) |> Effects.task
          ]
        )

    Deactivate ->
      let
        childModel =
          Leaflet.Update.update Leaflet.Update.ToggleMap model.leaflet
      in
        ( { model | leaflet = childModel }
        , Effects.none
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
