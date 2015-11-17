module WebAPI.Document
    ( ReadyState (Loading, Interactive, Complete)
    , readyState, getReadyState
    , getTitle, setTitle
    ) where

{-| See Mozilla documentation for the
[`Document` object](https://developer.mozilla.org/en-US/docs/Web/API/Document).

## Loading

@docs ReadyState, readyState, getReadyState

## Others

Since the browser's `document` object has so many facilities attached, I've
broken some of them up into individual modules -- see below for the
cross-references.

***See also***

**`cookie`**

&nbsp; &nbsp; &nbsp; &nbsp;
See [WebAPI.Cookie](#webapicookie)
-}


import Signal exposing (Signal)
import Task exposing (Task)
import Native.WebAPI.Document


{-| Possible values for the browser's `document.readyState` -}
type ReadyState
    = Loading
    | Interactive
    | Complete


{-| A `Signal` of changes to the browser's `document.readyState` -}
readyState : Signal ReadyState
readyState = Native.WebAPI.Document.readyState


{-| A task which, when executed, succeeds with the value of the browser's
`document.readyState`.
-}
getReadyState : Task x ReadyState
getReadyState = Native.WebAPI.Document.getReadyState


{-| A task which, when executed, succeeds with the value of `document.title`. -}
getTitle : Task x String
getTitle = Native.WebAPI.Document.getTitle


{-| A task which, when executed, sets the value of `document.title` to the
supplied `String`.
-}
setTitle : String -> Task x () 
setTitle = Native.WebAPI.Document.setTitle
