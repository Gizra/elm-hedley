module StorageExample where

import Effects exposing (Effects, Never)
import StartApp exposing (App)
import Task exposing (Task, toResult)
import Html exposing (Html, h4, div, text, button, input, select, option, label, table, tr, td)
import Html.Attributes exposing (id, style, value, type', selected, for, colspan)
import Html.Events exposing (onClick, on, targetValue)
import Signal exposing (Signal, Address)
import String

import WebAPI.Storage as Storage exposing (Storage)


{-| StartApp stuff. -}
app : App Model
app =
    StartApp.start
        { init = init
        , update = update
        , view = view
        , inputs = [ events ]
        }


main : Signal Html
main = app.html


port tasks : Signal (Task.Task Never ())
port tasks = app.tasks


{-| Our model is:

* a list of things that have happened (that we want to remember)
* an action which we're currently editing in the UI and might "send" at some point
* the last operation of each type which we've edited, so we can remember parameters
  as we switch operation types in the UI
-}
type alias Model =
    { log : List Log 
    , action : StorageAction 
    , lastOperation : LastOperation
    }


{-| We log:

* actions that we send to the storage objects
* the responses we get
* events received from other open windows, tabs, etc.
-}
type Log
    = LogAction StorageAction
    | LogResponse StorageResponse
    | LogEvent Storage.Event



{-| Our initial model. -}
init : (Model, Effects Action)
init = 
    ( { log = []
      , action =
          { target = Storage.local
          , operation = DoLength
          }
      , lastOperation =
          { key = DoKey 0
          , get = DoGet ""
          , set = DoSet "" ""
          , remove = DoRemove ""
          }
      }
    , Effects.none
    )


{-| I've modularized the Action type, even though it's all in one file. -}
type Action
    = SetAction SetAction
    | DoStorageAction StorageAction
    | StorageResponse StorageResponse
    | StorageEvent Storage.Event
    | NoOp


{-| Signal of events from other windows or tabs. -}
events : Signal Action
events = Signal.filterMap (Maybe.map StorageEvent) NoOp Storage.events


{-| We dispatch to more specific functions ... often they would be in separate
files, but I've put them all here.
-}
update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        SetAction subaction ->
            ( updateSetAction subaction model
            , Effects.none
            )

        DoStorageAction subaction ->
            updateStorageAction subaction model

        StorageResponse subaction ->
            updateStorageResponse subaction model

        StorageEvent subaction ->
            updateStorageEvent subaction model

        NoOp ->
            (model, Effects.none)


{-| These are actions from the UI ... thus, the strings. In principle, I could
use Json.Decode in the UI to supply typed data, but this works too.
-}
type SetAction
    = SetStorage String
    | SetOperationType String
    | SetKeyIndex String
    | SetGetKey String
    | SetSetKey String
    | SetSetValue String
    | SetRemoveKey String


{-| An action to send to a storage object. We edit this in the UI, and we
eventually send it in `Task` form.
-}
type alias StorageAction =
    { target : Storage
    , operation : StorageOperation
    }


{-| An operation to perform on a storage object. -}
type StorageOperation
    = DoLength
    | DoKey Int
    | DoGet Storage.Key
    | DoSet Storage.Key Storage.NewValue
    | DoRemove Storage.Key
    | DoClear


{-| Actually perform the StorageAction, and log it. -}
updateStorageAction : StorageAction -> Model -> (Model, Effects Action)
updateStorageAction action model =
    ( { model | log = LogAction action :: model.log }
    , Effects.task (Task.map StorageResponse (storageAction2task action))
    )


{- When we get a response, we just log it. -}
updateStorageResponse : StorageResponse -> Model -> (Model, Effects Action)
updateStorageResponse action model =
    ( { model | log = LogResponse action :: model.log }
    , Effects.none
    )


{- As with an event. -}
updateStorageEvent : Storage.Event -> Model -> (Model, Effects Action)
updateStorageEvent action model =
    ( { model | log = LogEvent action :: model.log }
    , Effects.none
    )


{-| We want to remember the parameters for the last operation we edited
of a given type, so that as we switch operation types the parameters can
be filled in.
-}
type alias LastOperation =
    { key : StorageOperation
    , get : StorageOperation
    , set : StorageOperation
    , remove : StorageOperation
    }


{-| This is for actions coming from the UI. -}
updateSetAction : SetAction -> Model -> Model
updateSetAction action model =
    let
        currentAction =
            model.action

        lastOperation =
            model.lastOperation

    in
        case action of
            SetStorage string ->
                let
                    storage =
                        if string == phrases.localStorage
                            then Storage.local
                        
                        else if string == phrases.sessionStorage
                            then Storage.session
                        
                        else
                            currentAction.target

                    newAction =
                        { currentAction | target = storage }

                in
                    { model | action = newAction } 

            SetOperationType string ->
                let
                    operation =
                        if string == phrases.length
                            then DoLength
                            
                        else if string == phrases.key
                            then
                                if doingKey currentAction.operation
                                    then currentAction.operation
                                    else lastOperation.key

                        else if string == phrases.get
                            then
                                if doingGet currentAction.operation
                                    then currentAction.operation
                                    else lastOperation.get

                        else if string == phrases.set
                            then
                                if doingSet currentAction.operation
                                    then currentAction.operation
                                    else lastOperation.set

                        else if string == phrases.remove
                            then
                                if doingRemove currentAction.operation
                                    then currentAction.operation
                                    else lastOperation.remove

                        else if string == phrases.clear
                            then
                                DoClear
                            
                        else
                            currentAction.operation

                    newAction =
                        { currentAction | operation = operation }
                    
                in
                    { model | action = newAction } 

            SetKeyIndex string ->
                let
                    operation =
                        case String.toInt string of
                            Ok int ->
                                DoKey int

                            Err _ ->
                                lastOperation.key

                    newAction =
                        { currentAction | operation = operation }

                    newLastOperation =
                        { lastOperation | key = operation }

                in
                    { model
                        | action = newAction
                        , lastOperation = newLastOperation
                    } 

            SetGetKey string ->
                let
                    operation =
                        DoGet string

                    newAction =
                        { currentAction | operation = operation }

                    newLastOperation =
                        { lastOperation | get = operation }
    
                in
                    { model
                        | action = newAction
                        , lastOperation = newLastOperation
                    } 

            SetRemoveKey string ->
                let
                    operation =
                        DoRemove string

                    newAction =
                        { currentAction | operation = operation }

                    newLastOperation =
                        { lastOperation | remove = operation }
    
                in
                    { model
                        | action = newAction
                        , lastOperation = newLastOperation
                    } 

            SetSetKey string ->
                let
                    operation =
                        case currentAction.operation of
                            DoSet key value ->
                                DoSet string value

                            _ ->
                                DoSet string ""
                    
                    newAction =
                        { currentAction | operation = operation }

                    newLastOperation =
                        { lastOperation | set = operation }
    
                in
                    { model
                        | action = newAction
                        , lastOperation = newLastOperation
                    } 

            SetSetValue string ->
                let
                    operation =
                        case currentAction.operation of
                            DoSet key value ->
                                DoSet key string

                            _ ->
                                DoSet "" string
                
                    newAction =
                        { currentAction | operation = operation }

                    newLastOperation =
                        { lastOperation | set = operation }
    
                in
                    { model
                        | action = newAction
                        , lastOperation = newLastOperation
                    } 


{-| A bunch of little convenience functions so that I don't have to write out
the pattern matches too often.
-}
doingLength : StorageOperation -> Bool
doingLength op =
    case op of
        DoLength -> True
        _ -> False


doingKey : StorageOperation -> Bool
doingKey op =
    case op of
        DoKey _ -> True
        _ -> False


doingGet : StorageOperation -> Bool
doingGet op =
    case op of
        DoGet _ -> True
        _ -> False


doingSet : StorageOperation -> Bool
doingSet op =
    case op of
        DoSet _ _ -> True
        _ -> False


doingRemove : StorageOperation -> Bool
doingRemove op =
    case op of
        DoRemove _ -> True
        _ -> False


doingClear : StorageOperation -> Bool
doingClear op =
    case op of
        DoClear -> True
        _ -> False


{- An Action type that wraps the various responses possible from
the storage tasks.
-}
type StorageResponse
    = HandleLength Int
    | HandleKey (Maybe Storage.Key)
    | HandleGet (Maybe Storage.Value)
    | HandleSet (Result String ())
    | HandleRemove ()
    | HandleClear ()


{-| A convenience function that takes a `StorageAction` and turns it into
a task that provides a `StorageResopnse`.
-}
storageAction2task : StorageAction -> Task x StorageResponse
storageAction2task action =
    case action.operation of
        DoLength ->
            Task.map HandleLength <|
                Storage.length action.target

        DoKey int ->
            Task.map HandleKey <|
                Storage.key action.target int

        DoGet key ->
            Task.map HandleGet <|
                Storage.get action.target key

        DoSet key value ->
            Task.map HandleSet <|
                Task.toResult <|
                    Storage.set action.target key value

        DoRemove key ->
            Task.map HandleRemove <|
                Storage.remove action.target key

        DoClear ->
            Task.map HandleClear <|
                Storage.clear action.target


{-| It's always nice to keep the actual text of the UI in one place. It also
helps for matching the <select> operations in the UI with the actual types.
-}
phrases =
    { localOrSession = "localStorage or sessionStorage? "
    , localStorage = "Local Storage"
    , sessionStorage = "Session Storage"
    , operation = "Operation? "
    , length = "length"
    , key = "key"
    , get = "get"
    , set = "set"
    , remove = "remove"
    , clear = "clear"
    , performAction = "Perform Action"
    , indexLabel = "Index? "
    , keyLabel = "Key? "
    , valueLabel = "Value? "
    }


{-| This takes a StorageAction and constructs an editor for it ... that is,
a bunch of HTML with <select> and <input> etc. so that you can edit the
StorageAction. Also, there is a button to actually perform the action.
-}
editStorageAction : Address Action -> StorageAction -> Html
editStorageAction address model =
    let
        notify func =
            Signal.message (Signal.forwardTo address SetAction) << func

        makeCell =
            td
                [ style
                    [ ("border", "1px dotted black")
                    , ("padding", "3px")
                    ]
                ]

        makeLabel id string =
            td
                [ style
                    [ ("text-align", "right")
                    , ("border", "1px dotted black")
                    , ("padding", "3px")
                    ]
                ]
                [ label
                    [ for id ]
                    [ text string ]
                ]

        objectSelector =
            tr []
                [ makeLabel "select-area" phrases.localOrSession 
                , makeCell 
                    [ select 
                        [ id "select-area" 
                        , on "change" targetValue (notify SetStorage)
                        ]
                        [ option
                            [ selected (model.target == Storage.local) ]
                            [ text phrases.localStorage ]
                        , option
                            [ selected (model.target == Storage.session) ]
                            [ text phrases.sessionStorage ]
                        ]
                    ]
                ]
   
        operationSelector =
            tr []
                [ makeLabel "select-operation" phrases.operation
                , makeCell
                    [ select
                        [ id "select-operation"
                        , on "change" targetValue (notify SetOperationType)
                        ]
                        [ option
                            [ selected (doingLength model.operation) ]
                            [ text phrases.length ]
                        , option
                            [ selected (doingKey model.operation) ]
                            [ text phrases.key ]
                        , option
                            [ selected (doingGet model.operation) ]
                            [ text phrases.get ]
                        , option
                            [ selected (doingSet model.operation) ]
                            [ text phrases.set ]
                        , option
                            [ selected (doingRemove model.operation) ]
                            [ text phrases.remove ]
                        , option
                            [ selected (doingClear model.operation) ]
                            [ text phrases.clear ]
                        ]
                    ]
                ]
        
        parameters =
            case model.operation of
                -- Nothing needed for DoLength
                DoLength ->
                    []

                DoKey index ->
                    [ tr []
                        [ makeLabel "select-index" phrases.indexLabel
                        , makeCell 
                            [ input
                                [ type' "number"
                                , id "select-index"
                                , value (toString index)
                                , on "input" targetValue (notify SetKeyIndex)
                                ] []
                            ]
                        ]
                    ]

                DoGet key ->
                    [ tr []
                        [ makeLabel "select-get-key" phrases.keyLabel
                        , makeCell
                            [ input
                                [ value key
                                , id "select-get-key"
                                , on "input" targetValue (notify SetGetKey)
                                ] []
                            ]
                        ]
                    ]

                DoSet key val ->
                    [ tr []
                        [ makeLabel "select-set-key" phrases.keyLabel
                        , makeCell
                            [ input
                                [ value key
                                , id "select-set-key"
                                , on "input" targetValue (notify SetSetKey)
                                ] []
                            ]
                        ]
                    , tr []
                        [ makeLabel "select-set-value" phrases.valueLabel
                        , makeCell 
                            [ input
                                [ value val
                                , id "select-set-value"
                                , on "input" targetValue (notify SetSetValue)
                                ] []
                            ]
                        ]
                    ]

                DoRemove key ->
                    [ tr []
                        [ makeLabel "select-remove-key" phrases.keyLabel
                        , makeCell
                            [ input
                                [ value key
                                , id "select-remove-key"
                                , on "input" targetValue (notify SetRemoveKey)
                                ] []
                            ]
                        ]
                    ]

                DoClear ->
                    []

        performAction =
            tr []
                [ td
                    [ colspan 2
                    , style
                        [ ("text-align", "center")
                        , ("border", "1px dotted black")
                        , ("padding", "3px")
                        ]
                    ]
                    [ button
                        [ id "perform-action" 
                        , onClick address (DoStorageAction model)
                        ]
                        [ text phrases.performAction ]
                    ]
                ]

    in
        table [] <|
            [ objectSelector
            , operationSelector
            ]
            ++
            parameters
            ++
            [ performAction
            ]


viewLog : Log -> Html
viewLog log =
    div 
        [ style [( "margin-top", "6pt")] ]
        [ text <| toString log ]


view : Address Action -> Model -> Html
view address model =
    div 
        [ style [ ("padding", "8px") ]
        ]
        [ editStorageAction address model.action

        , h4 [] [ text "Log (most recent first)" ]
        , div
            [ id "log" ] <|
            List.map viewLog model.log
        ]
