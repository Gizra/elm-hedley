module Example7.RandomGifList exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App exposing (map)
import Json.Decode as Json
import RouteHash exposing (HashUpdate)

import Example7.RandomGif as RandomGif


-- MODEL

type alias Model =
    { topic : String
    , gifList : List (Int, RandomGif.Model)
    , uid : Int
    }


init : (Model, Cmd Action)
init =
    ( Model "" [] 0
    , Cmd.none
    )


-- UPDATE

-- Add an action for the advanced example to set our state from a list
-- of topics and gifUrls
type Action
    = Topic String
    | Create
    | SubMsg Int RandomGif.Action
    | Set (List (String, Maybe String))


update : Action -> Model -> (Model, Cmd Action)
update message model =
    case message of
        Topic topic ->
            ( { model | topic = topic }
            , Cmd.none
            )

        Create ->
            let
                (newRandomGif, fx) =
                    RandomGif.init model.topic Nothing

                newModel =
                    Model "" (model.gifList ++ [(model.uid, newRandomGif)]) (model.uid + 1)
            in
                ( newModel
                , Cmd.map (SubMsg model.uid) fx
                )

        SubMsg msgId msg ->
            let
                subUpdate ((id, randomGif) as entry) =
                    if id == msgId then
                        let
                            (newRandomGif, fx) = RandomGif.update msg randomGif
                        in
                            ( (id, newRandomGif)
                            , Cmd.map (SubMsg id) fx
                            )
                    else
                        (entry, Cmd.none)

                (newGifList, fxList) =
                    model.gifList
                        |> List.map subUpdate
                        |> List.unzip
            in
                ( { model | gifList = newGifList }
                , Cmd.batch fxList
                )

        Set list ->
            let
                inits =
                    list |>
                        List.map (\(topic, url) ->
                            RandomGif.init topic url
                        )

                modelsAndEffects =
                    inits |>
                        List.indexedMap (\index item ->
                            ( (index, fst item)
                            , Cmd.map (SubMsg index) (snd item)
                            )
                        )

                (models, effects) =
                    List.unzip modelsAndEffects

            in
                ( { model
                        | gifList = models
                        , uid = List.length models
                  }
                , Cmd.batch effects
                )


-- VIEW

(=>) = (,)


view : Model -> Html Action
view model =
    div []
        [ input
            [ placeholder "What kind of gifs do you want?"
            , value model.topic
            , onEnter Create
            , onInput Topic
            , inputStyle
            ]
            []
        , div
            [ style
                [ "display" => "flex"
                , "flex-wrap" => "wrap"
                ]
            ]
            (List.map elementView model.gifList)
        ]


elementView : (Int, RandomGif.Model) -> Html Action
elementView (id, model) =
    map (SubMsg id) (RandomGif.view model)


inputStyle : Attribute any
inputStyle =
    style
        [ ("width", "100%")
        , ("height", "40px")
        , ("padding", "10px 0")
        , ("font-size", "2em")
        , ("text-align", "center")
        ]


onEnter : Action -> Attribute Action
onEnter action =
    on "keydown" <|
        Json.map
            (always action)
            (Json.customDecoder keyCode is13)


is13 : Int -> Result String ()
is13 code =
    if code == 13 then Ok () else Err "not the right key code"


-- We add a separate function to get a title, which the ExampleViewer uses to
-- construct a table of contents. Sometimes, you might have a function of this
-- kind return `Html` instead, depending on where it makes sense to do some of
-- the construction. Or, you could track the title in the higher level module,
-- if you prefer that.
title : String
title = "List of Random Gifs"


-- Routing

-- We record each thing in the gifList. Note that we don't track the ID's,
-- since in this app there isn't any need to preserve them ... of course, we
-- could track them if it mattered.
delta2update : Model -> Model -> Maybe HashUpdate
delta2update previous current =
    current.gifList
        |> List.filterMap (snd >> RandomGif.encodeLocation)
        |> List.concat
        |> RouteHash.set
        |> Just


location2action : List String -> List Action
location2action list =
    [ Set <|
        List.map (\(topic, url) ->
            if url == ""
                then (topic, Nothing)
                else (topic, Just url)
        )
        (inTwos list)
    ]


inTwos : List a -> List (a, a)
inTwos list =
    let
        step sublist result =
            case sublist of
                a :: b :: rest ->
                    step rest ((a, b) :: result)

                _ ->
                    result

    in
        List.reverse <|
            step list []
