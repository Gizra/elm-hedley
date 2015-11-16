module WebAPI.Storage
    ( Storage(Local, Session), local, session
    , length, key, get, set, remove, clear
    , events, Event, Change(Add, Remove, Modify, Clear)
    , Key, OldValue, NewValue, Value
    ) where


{-| Facilities from the browser's `Storage` areas (`localStorage` and `sessionStorage`).

See the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/Storage),
and the [WhatWG documentation](https://html.spec.whatwg.org/multipage/webstorage.html).

Note that there is a more sophisticated module for `Storage` at
[TheSeamau5/elm-storage](https://github.com/TheSeamau5/elm-storage)

## Storage Areas

@docs Storage, local, session

## Roles for Strings

@docs Key, OldValue, NewValue, Value

## Tasks 

@docs length, key, get, set, remove, clear

## Events 

@docs events, Event, Change

-}


import Task exposing (Task)
import Debug
import Native.WebAPI.Storage


{- -----------------
   Roles for Strings
   ----------------- -}

{-| A key. -}
type alias Key = String


{-| An old value. -}
type alias OldValue = String


{-| A new value. -}
type alias NewValue = String


{-| A value. -}
type alias Value = String


{- -------------
   Storage Areas 
   ------------- -}


{-| Represents the `localStorage` and `sessionStorage` areas. -}
type Storage
    = Local
    | Session


{-| The browser's `localStorage` area. -}
local : Storage
local = Local


{-| The browser's `sessionStorage` area. -}
session : Storage
session = Session


-- We expose a union type (above), rather than the actual native storage objects,
-- so that what we expose can be pattern-matched against etc.
type NativeStorage = NativeStorage


nativeLocal : NativeStorage
nativeLocal = Native.WebAPI.Storage.localStorage


nativeSession : NativeStorage
nativeSession = Native.WebAPI.Storage.sessionStorage


toNative : Storage -> NativeStorage
toNative storage =
    case storage of
        Local -> nativeLocal
        Session -> nativeSession


fromNative : NativeStorage -> Storage
fromNative native =
    if native == nativeLocal
        then Local
    else if native == nativeSession
        then Session
    else Debug.crash "There shouldn't be another kind of NativeStorage"


{- -----
   Tasks
   ----- -}


{-| A task which, when executed, determines the number of items stored in the
storage area.
-}
length : Storage -> Task x Int
length = nativeLength << toNative


nativeLength : NativeStorage -> Task x Int
nativeLength = Native.WebAPI.Storage.length


{-| A task which, when executed, determines the name of the key at the given
index (zero-based).
-}
key : Storage -> Int -> Task x (Maybe Key)
key storage = nativeKey (toNative storage)


nativeKey : NativeStorage -> Int -> Task x (Maybe Key)
nativeKey = Native.WebAPI.Storage.key


{-| A task which, when executed, gets the value at the given key. -}
get : Storage -> Key -> Task x (Maybe Value)
get storage = nativeGet (toNative storage)


nativeGet : NativeStorage -> Key -> Task x (Maybe Value)
nativeGet = Native.WebAPI.Storage.getItem


{-| A task which, when executed, sets the value at the given key, or fails with
an error message.
-}
set : Storage -> Key -> NewValue -> Task String ()
set storage = nativeSet (toNative storage)


nativeSet : NativeStorage -> Key -> NewValue -> Task String ()
nativeSet = Native.WebAPI.Storage.setItem


{-| A task which, when executed, removes the item with the given key. -}
remove : Storage -> Key -> Task x ()
remove storage = nativeRemove (toNative storage)


nativeRemove : NativeStorage -> Key -> Task x ()
nativeRemove = Native.WebAPI.Storage.removeItem


{-| A task which, when executed, removes all items. -}
clear : Storage -> Task x ()
clear = nativeClear << toNative


nativeClear : NativeStorage -> Task x ()
nativeClear = Native.WebAPI.Storage.clear


{- ------
   Events
   ------ -}


{- This is the signal produced by the native code ... this way, we can do
more of the processing in Elm, which is nicer.

Note that it is a `Maybe` because Elm signals must have initial values,
and there is no natural initial value for the `NativeEvent` itself unless
we wrap it in a `Maybe`.
-}
nativeEvents : Signal (Maybe NativeEvent)
nativeEvents = Native.WebAPI.Storage.nativeEvents


{- An event as produced by the native code. -}
type alias NativeEvent =
    { key : Maybe Key 
    , oldValue : Maybe OldValue
    , newValue : Maybe NewValue
    , url : String
    , storageArea : NativeStorage
    }


{-| A storage event. -}
type alias Event =
    { area : Storage
    , url : String
    , change : Change
    }


{-| A change to a storage area. -}
type Change
    = Add Key NewValue
    | Remove Key OldValue
    | Modify Key OldValue NewValue
    | Clear


nativeEvent2Change : NativeEvent -> Change
nativeEvent2Change native =
    case (native.key, native.oldValue, native.newValue) of
        (Nothing, _, _) ->
            Clear

        -- Safari does this
        (Just "", _, _) ->
            Clear

        (Just key, Just oldValue, Nothing) ->
            Remove key oldValue

        (Just key, Nothing, Just newValue) ->
            Add key newValue

        (Just key, Just oldValue, Just newValue) ->
            Modify key oldValue newValue

        (_, Nothing, Nothing) ->
            Debug.crash "The browser should never emit this."


nativeEvent2Event : NativeEvent -> Event
nativeEvent2Event native =
    { area = fromNative native.storageArea
    , url = native.url
    , change = nativeEvent2Change native
    }
        

{-| A signal of storage events.

Note that a storage event is not fired within the same document that made a
storage change. Thus, you will only receive events for localStorage changes
that occur in a **separate** tab or window.

This behaviour reflects how Javascript does things ... let me know if you'd
prefer to have *all* localStorage events go through this `Signal` -- it could
be arranged.

At least in Safari, sessionStorage is even more restrictive than localStorage
-- it is isolated per-tab, so you will only get events on sessionStorage if
using iframes.

Note that this signal emits `Maybe Event` (rather than `Event`) because Elm
signals must have an initial value -- and there is no natural initial value for
an `Event` unless we wrap it in a `Maybe`. So, you'll often want to use
`Signal.filterMap` when you're integrating this into your own signal of
actions.
-}
events : Signal (Maybe Event)
events =
    Signal.map (Maybe.map nativeEvent2Event) nativeEvents
