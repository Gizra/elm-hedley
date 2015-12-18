module Pages.Event.Router where

import Pages.Event.Model as Event exposing (Model)
import RouteHash exposing (HashUpdate)
import String exposing (toInt)

delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
  let
    url =
      case current.eventCompanyFilter of
        Just companyId -> [ toString (companyId) ]
        Nothing -> []
  in
    Just <| RouteHash.set url

location2company : List String -> Maybe Int
location2company list =
  case List.head list of
    Just eventId ->
      case String.toInt eventId of
        Ok val ->
          Just val
        Err _ ->
          Nothing

    Nothing ->
      Nothing
