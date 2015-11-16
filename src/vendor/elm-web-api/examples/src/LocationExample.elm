module LocationExample where

import Effects exposing (Effects, Never)
import StartApp exposing (App)
import Task exposing (Task, toResult)
import Html exposing (Html, h4, div, text, button, input)
import Html.Attributes exposing (id)
import Html.Events exposing (onClick)
import Signal exposing (Signal, Address)

import WebAPI.Location exposing (reload, Source(..))


app : App Model
app =
    StartApp.start
        { init = init
        , update = update
        , view = view
        , inputs = []
        }


main : Signal Html
main = app.html


port tasks : Signal (Task.Task Never ())
port tasks = app.tasks


type alias Model = String


init : (Model, Effects Action)
init = ("Initial state", Effects.none)


type Action
    = Reload Source
    | HandleReload (Result String ())


update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        HandleReload result ->
            ( "Reloaded (but if this stays, then that's an error)"
            , Effects.none
            )

        Reload source ->
            ( "About to reload"
            , reload source |>
                toResult |>
                    Task.map HandleReload |>
                        Effects.task
            )


view : Address Action -> Model -> Html
view address model =
    div []
        [ button
            [ id "reload-force-button" 
            , onClick address (Reload ForceServer)
            ]
            [ text "WebAPI.Location.reload ForceServer" ]
        , button
            [ id "reload-cache-button" 
            , onClick address (Reload AllowCache)
            ]
            [ text "WebAPI.Location.reload AllowCache" ]
        , h4 [] [ text "Message" ]
        , div [ id "message" ] [ text model ]
        , input [ id "input" ] []
        ]

