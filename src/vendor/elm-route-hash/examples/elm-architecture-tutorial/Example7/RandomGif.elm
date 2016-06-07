module Example7.RandomGif exposing (..)

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Json
import Task


-- MODEL

-- In the advanced example, it's easier to track the gifUrl as a Maybe String
-- and apply the default value later, since the default value is really a
-- question for the view, rather than the model.
type alias Model =
    { topic : String
    , gifUrl : Maybe String
    }


-- We provide for initializing with the gifUrl already set, since that is how
-- the routing will do it. If the gifUrl is provided, then we skip getting a
-- random one.
init : String -> Maybe String -> (Model, Cmd Action)
init topic gifUrl =
  ( Model topic gifUrl
  , if gifUrl == Nothing
        then getRandomGif topic
        else Cmd.none
  )


-- UPDATE

type Action
    = RequestMore
    | HttpError Http.Error
    | NewGif String


update : Action -> Model -> (Model, Cmd Action)
update action model =
  case action of
    RequestMore ->
      (model, getRandomGif model.topic)

    NewGif url ->
      ( Model model.topic (Just url)
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
    , div [imgStyle (Maybe.withDefault "assets/waiting.gif" model.gifUrl)] []
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

-- Instead of using the same signature all the way down, we'll simplify this
-- case a little.
encodeLocation : Model -> Maybe (List String)
encodeLocation model =
    -- Don't encode if there's no gifUrl
    if (model.gifUrl == Nothing)
        then
            Nothing

        else
            Just
                [ model.topic
                , Maybe.withDefault "" model.gifUrl
                ]
