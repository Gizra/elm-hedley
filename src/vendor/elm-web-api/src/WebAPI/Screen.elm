module WebAPI.Screen
    ( Screen, screen
    , screenXY
    ) where


{-| The browser's `Screen` type from `window.screen`.

See the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/Screen).

@docs Screen, screen

@docs screenXY
-}

import Task exposing (Task)

import Native.WebAPI.Screen


{-| The browser's `Screen` type. -}
type alias Screen =
    { availTop: Int
    , availLeft: Int
    , availHeight: Int
    , availWidth: Int
    , colorDepth: Int
    , pixelDepth: Int
    , height: Int
    , width: Int
    }


{-| The browser's `window.screen` object.

This is a `Task` because in multi-monitor setups, the result depends on which screen
the browser window is in. So, it is not necessarily a constant.
-}
screen : Task x Screen
screen = Native.WebAPI.Screen.screen


{-| A tuple of the browser's `(window.screenX, window.screenY)`.

    The first value is the horizontal distance, in CSS pixels, of the left
    border of the user's browser from the left side of the screen.

    The second value is the vertical distance, in CSS pixels, of the top border
    of the user's browser from the top edge of the screen.
-}
screenXY : Task x (Int, Int)
screenXY = Native.WebAPI.Screen.screenXY
