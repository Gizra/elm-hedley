module Example6.RandomGifPair exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App exposing (map)
import RouteHash exposing (HashUpdate)

import Example6.RandomGif as RandomGif


-- MODEL

type alias Model =
    { left : RandomGif.Model
    , right : RandomGif.Model
    }


-- Rewrote to move initialization strings from Main.elm
init : (Model, Cmd Action)
init =
  let
    leftTopic = "funny cats"
    rightTopic = "funny dogs"
    (left, leftFx) = RandomGif.init leftTopic
    (right, rightFx) = RandomGif.init rightTopic
  in
    ( Model left right
    , Cmd.batch
        [ Cmd.map Left leftFx
        , Cmd.map Right rightFx
        ]
    )


-- UPDATE

type Action
    = Left RandomGif.Action
    | Right RandomGif.Action


update : Action -> Model -> (Model, Cmd Action)
update action model =
  case action of
    Left act ->
      let
        (left, fx) = RandomGif.update act model.left
      in
        ( Model left model.right
        , Cmd.map Left fx
        )

    Right act ->
      let
        (right, fx) = RandomGif.update act model.right
      in
        ( Model model.left right
        , Cmd.map Right fx
        )


-- VIEW

view : Model -> Html Action
view model =
  div [ style [ ("display", "flex") ] ]
    [ map Left (RandomGif.view model.left)
    , map Right (RandomGif.view model.right)
    ]


-- We add a separate function to get a title, which the ExampleViewer uses to
-- construct a table of contents. Sometimes, you might have a function of this
-- kind return `Html` instead, depending on where it makes sense to do some of
-- the construction. Or, you could track the title in the higher level module,
-- if you prefer that.
title : String
title = "Pair of Random Gifs"


-- Routing

delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
    let
        left =
            Maybe.map RouteHash.extract <|
                RandomGif.delta2update previous.left current.left

        right =
            Maybe.map RouteHash.extract <|
                RandomGif.delta2update previous.right current.right

    in
        -- Essentially, we want to combine left and right. I should think about
        -- how to improve the API for this. We can simplify in this case because
        -- we happen to know that both sides will be lists of length 1. If the
        -- lengths could vary, we'd have to do something more complex.
        Maybe.map RouteHash.set <|
            left `Maybe.andThen` (\l ->
                right `Maybe.andThen` (\r ->
                    Just (l ++ r)
                )
            )


location2action : List String -> List Action
location2action list =
    -- This is simplified because we know that each sub-module will supply a
    -- list with one element ... otherwise, we'd have to do something more
    -- complex.
    case list of
        left :: right :: rest ->
            List.concat
                [ List.map Left <| RandomGif.location2action [left]
                , List.map Right <| RandomGif.location2action [right]
                ]

        _ ->
            []
