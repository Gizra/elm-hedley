module Example6.RandomGif exposing (..)

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Json
import Task
import RouteHash exposing (HashUpdate)


-- MODEL

-- For the advanced example, we need to keep track of a status in order to deal
-- with the fact that a request for a random gif may be in progress when our
-- location changes. In that case, we want (in effect) to cancel the request.
type alias Model =
    { topic : String
    , gifUrl : String
    , requestStatus : RequestStatus
    }


-- Tracks whether we should use or ignore the response from getRandomGif
type RequestStatus
    = Use 
    | Ignore


-- We start the requestStatus as Use so that we will use the response to the
-- initial request we issue here.
init : String -> (Model, Cmd Action)
init topic =
  ( Model topic "assets/waiting.gif" Use
  , getRandomGif topic
  )


-- UPDATE

-- We end up needing a separate action for setting the gif from the location,
-- because in that case we also need to "cancel" any outstanding requests for a
-- random gif.
type Action
    = RequestMore
    | HttpError Http.Error
    | NewGif String
    | NewGifFromLocation String


update : Action -> Model -> (Model, Cmd Action)
update action model =
  case action of
    RequestMore ->
      -- When we're explicitly asked to get a random gif, then mark that
      -- we should use the response.
      ( { model | requestStatus = Use }
      , getRandomGif model.topic
      )

    NewGif url ->
        case model.requestStatus of
            Use ->
                ( { model | gifUrl = url }
                , Cmd.none
                )

            -- This will be set to ignore if our location has changed since
            -- the request was issued. In that case, we want to ignore the
            -- result of the randomGif request (which was, of course, async)
            Ignore ->
                ( model, Cmd.none )

    NewGifFromLocation url ->
        -- When we get the gif from the URL, then ignore any randomGif requests
        -- that haven't resolved yet.
        ( { model
                | gifUrl = url
                , requestStatus = Ignore
          }
        , Cmd.none
        )

    HttpError error ->
        -- Should really show the error ... do nothing for now.
        ( model, Cmd.none )

-- VIEW

(=>) = (,)


view : Model -> Html Action
view model =
  div [ style [ "width" => "200px" ] ]
    [ h2 [headerStyle] [text model.topic]
    , div [imgStyle model.gifUrl] []
    , button [ onClick RequestMore ] [ text "More Please!" ]
    ]


headerStyle : Attribute any
headerStyle =
  style
    [ "width" => "200px"
    , "text-align" => "center"
    ]


imgStyle : String -> Attribute any
imgStyle url =
  style
    [ "display" => "inline-block"
    , "width" => "200px"
    , "height" => "200px"
    , "background-position" => "center center"
    , "background-size" => "cover"
    , "background-image" => ("url('" ++ url ++ "')")
    ]


-- EFFECTS

getRandomGif : String -> Cmd Action
getRandomGif topic =
  Http.get decodeUrl (randomUrl topic)
    |> Task.perform HttpError NewGif


randomUrl : String -> String
randomUrl topic =
  Http.url "http://api.giphy.com/v1/gifs/random"
    [ "api_key" => "dc6zaTOxFJmzC"
    , "tag" => topic
    ]


decodeUrl : Json.Decoder String
decodeUrl =
  Json.at ["data", "image_url"] Json.string


-- Routing

-- We'll generate URLs like "/gifUrl". Note that this treats the topic as an
-- invariant, which it is here ... it can only be supplied on initialization.
-- If it weren't invariant, we'd need to do something more complex.
delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
    if current.gifUrl == "assets/waiting.gif" 
        then
            -- If we're waiting for the first random gif, don't generate an entry ...
            -- wait for the gif to arrive.
            Nothing

        else
            Just (RouteHash.set [current.gifUrl])


location2action : List String -> List Action
location2action list =
    case list of
        -- If we have a gifUrl, then use it
        gifUrl :: rest ->
            [ NewGifFromLocation gifUrl ]

        -- Otherwise, do nothing
        _ ->
            []
