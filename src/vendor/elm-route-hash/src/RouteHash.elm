module RouteHash exposing
    ( HashUpdate, set, replace, apply, map, extract
    , Config, ConfigWithFlags, defaultPrefix
    , app, appWithFlags
    , program, programWithFlags
    )


{-| This module implements the elm-route-hash 1.x API as closely as possible,
given the changes required for elm-route-hash 2.0.

# Configuration

@docs Config, ConfigWithFlags, defaultPrefix

# Helpers for `HashUpdate`

@docs HashUpdate, set, replace, apply, map, extract

# Simple Initialization

@docs program, programWithFlags

# Complicated Initialization (usually not needed)

@docs app, appWithFlags
-}


import String exposing (uncons, split)
import Http exposing (uriDecode, uriEncode)
import Html exposing (Html)
import Navigation exposing (Location)

import RouteUrl exposing
    ( NavigationApp, App, AppWithFlags
    , UrlChange, HistoryEntry(NewEntry, ModifyEntry)
    , runNavigationApp
    )


{-| An opaque type which represents an update to the hash portion of the
browser's location.
-}
type HashUpdate
    = SetPath (List String)
    | ReplacePath (List String)


hashUpdate2urlChange : String -> HashUpdate -> UrlChange
hashUpdate2urlChange prefix hashUpdate =
    case hashUpdate of
        SetPath list ->
            { entry = NewEntry
            , url = list2hash prefix list
            }

        ReplacePath list ->
            { entry = ModifyEntry
            , url = list2hash prefix list
            }


{-| Returns a [`HashUpdate`](#HashUpdate) that will update the browser's
location, creating a new history entry.

The `List String` represents the hash portion of the location. Each element of
the list will be uriEncoded, and then the list will be joined using slashes
("/"). Finally, a prefix will be applied (by [default](#defaultPrefix), "#!/",
but it is configurable).
-}
set : List String -> HashUpdate
set = SetPath


{-| Returns a [`HashUpdate`](#HashUpdate) that will update the browser's
location, replacing the current history entry.

The `List String` represents the hash portion of the location. Each element of
the list will be uriEncoded, and then the list will be joined using slashes
("/"). Finally, a prefix will be applied (by [default](#defaultPrefix), "#!/",
but it is configurable).
-}
replace : List String -> HashUpdate
replace = ReplacePath


{-| Applies the supplied function to the [`HashUpdate`](#HashUpdate). -}
apply : (List String -> List String) -> HashUpdate -> HashUpdate
apply func update =
    case update of
        SetPath list ->
            SetPath (func list)

        ReplacePath list ->
            ReplacePath (func list)


{-| Applies the supplied function to the [`HashUpdate`](#HashUpdate).

You might use this function when dispatching in a modular application.
For instance, your [`delta2update`](#Config) function might look something like this:

    delta2update : Model -> Model -> Maybe HashUpdate
    delta2update old new =
        case new.virtualPage of
            PageTag1 ->
                RouteHash.map ((::) "page-tag-1") PageModule1.delta2update old new

            PageTag2 ->
                RouteHash.map ((::) "page-tag-2") PageModule2.delta2update old new

Of course, your model and modules may be set up differently. However you do it,
the `map` function allows you to dispatch `delta2update` to a lower-level module,
and then modify the `Maybe HashUpdate` which it returns.
-}
map : (List String -> List String) -> Maybe HashUpdate -> Maybe HashUpdate
map = Maybe.map << apply


{-| Extracts the `List String` from the [`HashUpdate`](#HashUpdate). -}
extract : HashUpdate -> List String
extract action =
    case action of
        SetPath list ->
            list

        ReplacePath list ->
            list


{-| Represents the configuration necessary to use this module.

*  `prefix` is the initial characters that should be stripped from the hash (if
    present) when reacting to location changes, and added to the hash when
    generating location changes. Normally, you'll likely want to use
    [`defaultPrefix`](#defaultPrefix), which is "#!/".

*   `delta2update` is a function which takes two arguments and possibly
    returns a [`HashUpdate`](#HashUpdate). The first argument is the previous
    model. The second argument is the current model.

    The reason you are provided with both the previous and current models is
    that sometimes the nature of the location update depends on the difference
    between the two, not just on the latest model. For instance, if the user is
    typing in a form, you might want to use [`replace`](#replace) rather than
    [`set`](#set). Of course, in cases where you only need to consult the
    current model, you can ignore the first parameter.

    This module will normalize the `List String` in the update in the following
    way before setting the actual location. It will:

    * uriEncode the strings
    * join them with "/"
    * add the `prefix` to the beginning

    In a modular application, you may well want to use [`map`](#map) after dispatching
    to a lower level -- see the example in the [`map` documentation](#map).

    Note that this module will automatically detect cases where you return
    a [`HashUpdate`](#HashUpdate) which would set the same location that is
    already set, and do nothing. Thus, you don't need to try to detect that
    yourself.

    The content of the individual strings is up to you ... essentially it
    should be something that your `location2action` function can deal with.

*   `location2action` is a function which takes a `List String` and returns
    a list of actions your app can perform.

    The argument is a normalized version of the hash portion of the location.
    First, the `prefix` is stripped from the hash, and then the result is
    converted to a `List String` by using '/' as a delimiter. Then, each
    `String` value is uriDecoded.

    Essentially, your `location2action` should return actions that are the
    reverse of what your `delta2update` function produced. That is, the
    `List String` you get back in `location2action` is the `List String` that
    your `delta2update` used to create a [`HashUpdate`](#HashUpdate). So,
    however you encoded your state in `delta2update`, you now need to interpret
    that in `location2action` in order to return actions which will produce the
    desired state.

    Note that the list of actions you return will often be a single action. It
    is a `List action` so that you can return multiple actions, if your app is
    modular in a way that requires multiple actions to produce the desired
    state.

*   The remaining functions (`init`, `update`, `subscriptions` and `view`)
    have the same meaning as they do in
    [`Html.App.program`](http://package.elm-lang.org/packages/elm-lang/html/1.0.0/Html-App#program)
    ... that is, you should provide what you normally provide to that function.
-}
type alias Config model msg =
    { prefix : String
    , delta2update : model -> model -> Maybe HashUpdate
    , location2action : List String -> List msg
    , init : (model, Cmd msg)
    , update : msg -> model -> (model, Cmd msg)
    , subscriptions : model -> Sub msg
    , view : model -> Html msg
    }


{-| Like `Config`, but with flags. -}
type alias ConfigWithFlags model msg flags =
    { prefix : String
    , delta2update : model -> model -> Maybe HashUpdate
    , location2action : List String -> List msg
    , init : flags -> (model, Cmd msg)
    , update : msg -> model -> (model, Cmd msg)
    , subscriptions : model -> Sub msg
    , view : model -> Html msg
    }


{-| The value that you will most often want to supply as the
`prefix` in your [`Config`](#Config). It is equal to "#!/".
-}
defaultPrefix : String
defaultPrefix = "#!/"


location2messages : ConfigWithFlags model msg flags -> Location -> List msg
location2messages config location =
    config.location2action (hash2list config.prefix location.hash)


delta2url : ConfigWithFlags model msg flags -> model -> model -> Maybe UrlChange
delta2url config old new =
    Maybe.map
        (hashUpdate2urlChange config.prefix)
        (config.delta2update old new)


{-| Takes your configuration, and turns into into an `AppWithFlags`.

Usually you won't need this -- you can just use [`programWithFlags`](#programWithFlags) to
go directly to a `Program` instead.
-}
appWithFlags : ConfigWithFlags model msg flags -> AppWithFlags model msg flags
appWithFlags config =
    { delta2url = delta2url config
    , location2messages = location2messages config
    , init = config.init
    , update = config.update
    , subscriptions = config.subscriptions
    , view = config.view
    }


{-| Takes your configuration, and turns it into an `AppWithFlags`.

Usually you won't need this -- you can just use [`program`](#program) to
go directly to a `Program` instead.
-}
app : Config model msg -> AppWithFlags model msg Never
app config =
    appWithFlags
        { config | init = \_ -> config.init }


{-| Takes your configuration, and turns it into a `Program` that can be
used in your `main` function.
-}
program : Config model msg -> Program Never
program = runNavigationApp << RouteUrl.navigationAppWithFlags << app


{-| Takes your configuration, and turns it into a `Program` that can be
used in your `main` function.
-}
programWithFlags : ConfigWithFlags model msg flags -> Program flags
programWithFlags = runNavigationApp << RouteUrl.navigationAppWithFlags << appWithFlags


{-| Remove the character from the string if it is the first character -}
removeInitial : Char -> String -> String
removeInitial initial original =
    case uncons original of
        Just (first, rest) ->
            if first == initial
                then rest
                else original

        _ ->
            original


{-| Remove initial characters from the string, as many as there are.

So, for "#!/", remove # if is first, then ! if it is next, etc.
-}
removeInitialSequence : String -> String -> String
removeInitialSequence initial original =
    String.foldl removeInitial original initial


{-| Takes a string from the location's hash, and normalize it to a list of strings
that were separated by a slash.
-}
hash2list : String -> String -> List String
hash2list prefix =
    removeInitialSequence prefix >> split "/" >> List.map uriDecode


{-| The opposite of normalizeHash ... takes a list and turns it into a hash -}
list2hash : String -> List String -> String
list2hash prefix list =
    prefix ++ String.join "/" (List.map uriEncode list)
