module WebAPI.Location
    ( Location, location
    , reload, Source(ForceServer, AllowCache)
    ) where


{-| Facilities from the browser's `window.location` object.

See the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/Location)

For a `Signal`-oriented version of things you might do with `window.location`, see
[TheSeamau5/elm-history](http://package.elm-lang.org/packages/TheSeamau5/elm-history/latest).

For `assign`, use `setPath` from
[TheSeamau5/elm-history](http://package.elm-lang.org/packages/TheSeamau5/elm-history/latest).

For `replace`, use `replacePath` from
[TheSeamau5/elm-history](http://package.elm-lang.org/packages/TheSeamau5/elm-history/latest).

@docs Location, location, reload, Source
-}


import Task exposing (Task)
import Native.WebAPI.Location


{-| The parts of a location object. Note `port'`, since `port` is a reserved word. -}
type alias Location =
    { href: String
    , protocol: String
    , host: String
    , hostname: String
    , port': String
    , pathname: String
    , search: String
    , hash: String
    , origin: String
    }


{-| The browser's `window.location` object. -}
location : Task x Location
location = Native.WebAPI.Location.location 


{-| Reloads the page from the current URL.-}
reload : Source -> Task String ()
reload source =
    nativeReload <|
        case source of
            ForceServer -> True
            AllowCache -> False


nativeReload : Bool -> Task String ()
nativeReload = Native.WebAPI.Location.reload


{-| Whether to force `reload` to use the server, or allow the cache. -}
type Source
    = ForceServer
    | AllowCache
