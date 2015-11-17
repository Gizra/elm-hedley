module WebAPI.Window
    ( alert, confirm, prompt
    ) where


{-| Facilities from the browser's `window` object.

See the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/Window)

Note that some things on the browser's `window` object are handled through other
modules here. For instance:

*   localStorage, sessionStorage
    See `WebAPI.Storage`

*   location
    See `WebAPI.Location`

*   screen, screenX, screenY
    See `WebAPI.Screen`

*   requestAnimationFrame, cancelAnimationFrame
    See `WebAPI.AnimationFrame`

@docs alert, confirm, prompt
-}


import Task exposing (Task)
import Native.WebAPI.Window


{-| The browser's `window.alert()` function.
-}
alert : String -> Task x ()
alert = Native.WebAPI.Window.alert


{-| The browser's `window.confirm()` function.

The task will succeed if the user confirms, and fail if the user cancels.
-}
confirm : String -> Task () ()
confirm = Native.WebAPI.Window.confirm


{-| The browser's `window.prompt()` function.

The first parameter is a message, and the second parameter is a default
response.

The task will succeed with the user's response, or fail if the user cancels
or enters blank text.
-}
prompt : String -> String -> Task () String
prompt = Native.WebAPI.Window.prompt

