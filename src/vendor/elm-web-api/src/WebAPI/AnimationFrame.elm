module WebAPI.AnimationFrame
    ( task
    , Request, request, cancel
    ) where


{-| Bindings for `window.requestAnimationFrame()` and `window.cancelAnimationFrame`.

Note that 
[jwmerrill/elm-animation-frame](http://package.elm-lang.org/packages/jwmerrill/elm-animation-frame/latest)
provides for a `Signal` of animation frames. So, this module merely provides a
`Task`-oriented alternative.

Other higher-level alternatives include 
[evancz/elm-effects](http://package.elm-lang.org/packages/evancz/elm-effects/latest)
and [rgrempel/elm-ticker](https://github.com/rgrempel/elm-ticker.git).

@docs task, request, Request, cancel
-}


import Time exposing (Time)
import Task exposing (Task)
import Native.WebAPI.AnimationFrame


{-| A task which, when executed, will call `window.requestAnimationFrame()`.
The task will complete when `requestAnimationFrame()` fires its callback, and
will pass along the value provided by the callback.

So, to do something when the callback fires, just add an `andThen` to the task.
-}
task : Task x Time
task = Native.WebAPI.AnimationFrame.task


{-| Opaque type which represents an animation frame request. -}
type Request = Request


{-| A more complex implementation of `window.requestAnimationFrame()` which
allows for cancelling the request.

Returns a `Task` which, when executed, will call
`window.requestAnimationFrame()`, and then immediately complete with the
identifier returned by `requestAnimationFrame()`.  You can supply this
identifier to `cancel` if you want to cancel the request.

Assuming that you don't cancel the request, the following sequence of events will occur:

* `window.requestAnimationFrame()` will eventually fire its callback, providing a timestamp
* Your function will be called with that timestamp
* The `Task` returned by your function will be immediately executed
-}
request : (Time -> Task x a) -> Task y Request
request = Native.WebAPI.AnimationFrame.request


{-| Returns a task which, when executed, will cancel the supplied request
via `window.cancelAnimationFrame()`.
-}
cancel : Request -> Task x ()
cancel = Native.WebAPI.AnimationFrame.cancel 
