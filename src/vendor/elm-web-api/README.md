[![Build Status](https://travis-ci.org/rgrempel/elm-web-api.svg)](https://travis-ci.org/rgrempel/elm-web-api)

[![Sauce Test Status](https://saucelabs.com/browser-matrix/elm-web-api.svg)](https://saucelabs.com/u/elm-web-api)

# elm-web-api

The purpose of this package is to expose various standard web APIs to Elm,
or document where they are already exposed.

By "web APIs" I basically mean the kind of things that are listed on
Mozilla's various Web APIs pages, e.g.

* https://developer.mozilla.org/en-US/docs/Web/API
* https://developer.mozilla.org/en-US/docs/WebAPI
* https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference

Essentially, they are various facilities available in a Javascript web
environment. 

In order for Elm to use such facilities, it is necessary to write "native"
code. So, I'm plugging away at it -- this is a work in progress.


## Contents

* [Supported browsers](#supportedbrowsers)
* [Installation](#installation)
* APIs
    * [WebAPI.AnimationFrame](#webapianimationframe)
    * [WebAPI.Cookie](#webapicookie)
    * [WebAPI.Document](#webapidocument)
    * [WebAPI.Date](#webapidate)
    * [WebAPI.Location](#webapilocation)
    * [WebAPI.Math](#webapimath)
    * [WebAPI.Number](#webapinumber)
    * [WebAPI.Screen](#webapiscreen)
    * [WebAPI.Storage](#webapistorage)
    * [WebAPI.Window](#webapiwindow)


## Supported browsers

I have now set up testing via Travis and SauceLabs, and you can see at the top
of this page a graphic that indicates which browsers I'm testing against.
Let me know if you think I should try out some older verions as well.

For the moment, I'm not thinking too hard about supporting node.js as well.
That's a somewhat larger issue for Elm (it requires some shimming even to get
elm-lang/core to work). Furthermore, it might make sense to have a separate
package to wrap node.js-oriented APIs (and provide appropriate shims), even if
there is some overlap.


## Installation

Because elm-web-api uses "native" modules, it requires approval before it can
be included in the
[Elm package repository](http://package.elm-lang.org/packages). For a variety of
reasons, it's unlikely to get such approval. Thus, you cannot currently install
it using `elm-package`.

However, you can still install it and use it via the following steps:

*   Download this respository in one way or another. For instance, you might use:

        git clone https://github.com/rgrempel/elm-web-api.git

    Or, you might use git submodules, if you're adept at that. (I wouldn't suggest
    trying it if you've never heard of them before).

*   Modify your `elm-package.json` to refer to the `src` folder.

    You can choose where you want to put the downloaded code, but wherever that
    is, simply modify your `elm-package.json` file so that it can find the
    `src` folder.  So, the "source-directories" entry in your
    `elm-package.json` file might end up looking like this:

        "source-directories": [
            "src",
            "elm-web-api/src"
        ],

    But, of course, that depends on where you've actually put it, and where the
    rest of your code is.

*   Modify your `elm-package.json` to indicate that you're using 'native' modules.
    To do this, add the following entry to `elm-package.json`:

        "native-modules": true,

Now, doing this would have several implications which you should be aware of.

*   You would, essentially, be trusting me (or looking to verify for yourself)
    that the native code in this module is of high quality and will not cause
    run-time errors or other problems.

*   You would be relying on me to update that code when the mechanism for using
    'native' modules in Elm changes, or when certain other internal details of Elm's
    implementation change. Furthermore, you'd have to check here whenever the Elm
    compiler's version changes, or the Elm core library's version changes, to see
    whether an update is required.

*   If you're using this as part of a module you'd like to publish yourself,
    then you'll now also need approval before becoming available on the Elm
    package repository.

So, you may or may not really want to do this. But I thought it would be nice to
let you know how.


## APIs

### WebAPI.AnimationFrame

Bindings for 
[`window.requestAnimationFrame()`](https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame)
and [`window.cancelAnimationFrame`](https://developer.mozilla.org/en-US/docs/Web/API/Window/cancelAnimationFrame).

Note that 
[jwmerrill/elm-animation-frame](http://package.elm-lang.org/packages/jwmerrill/elm-animation-frame/latest)
provides for a `Signal` of animation frames. So, this module merely provides a
`Task`-oriented alternative.

Other higher-level alternatives include 
[evancz/elm-effects](http://package.elm-lang.org/packages/evancz/elm-effects/latest)
and [rgrempel/elm-ticker](https://github.com/rgrempel/elm-ticker.git).

```elm
module WebAPI.AnimationFrame where

{-| A task which, when executed, will call `window.requestAnimationFrame()`.
The task will complete when `requestAnimationFrame()` fires its callback, and
will pass along the value provided by the callback.

So, to do something when the callback fires, just add an `andThen` to the task.
-}
task : Task x Time

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

{-| Opaque type which represents an animation frame request. -}
type Request

{-| Returns a task which, when executed, will cancel the supplied request
via `window.cancelAnimationFrame()`.
-}
cancel : Request -> Task x ()
```


-----------------

### WebAPI.Cookie

Wraps the browser's 
[`document.cookie`](https://developer.mozilla.org/en-US/docs/Web/API/Document/cookie)
object.

```elm
module WebAPI.Cookie where

{-| A `Task` which, when executed, will succeed with the cookies.

In the resulting `Dict`, the keys and values are the key=value pairs parsed from
Javascript's `document.cookie`. The keys and values will have been uriDecoded.
-}
get : Task x (Dict String String)

{-| A task which will set a cookie using the provided key (first parameter)
and value (second parameter).

The key and value will both be uriEncoded.
-}
set : String -> String -> Task x ()

{-| A task which will set a cookie using the provided options, key (second
parameter), and value (third parameter).

The key and value will be uriEncoded, as well as the path and domain options
(if provided).
-}
setWith : Options -> String -> String -> Task x ()

{-| Options which you can provide to setWith. -}
type alias Options =
    { path : Maybe String
    , domain : Maybe String
    , maxAge : Maybe Time
    , expires : Maybe Date 
    , secure : Maybe Bool
    }

{-| The default options, in which all options are set to `Nothing`.

You can use this as a starting point for `setWith`, where you only want to
specify some options.
-}
defaultOptions : Options
```

-----------------

### WebAPI.Date

Generally speaking, dates are dealt with by the `Date` and `Time` modules in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

See [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date).

Truly dealing with all the complexity of dates requires something that goes
far beyond the Javascript API -- for instance, one could ideally think in terms
of wrapping (or, even better, porting) the [moment.js](http://momentjs.com)
library (or something even better).

That isn't in scope for this module. Instead, this is intended merely to be a
thin wrapper over the Javascript `Date` API, such as it is.

```elm
module WebAPI.Date where

{- --------------------------------- 
   Getting the current date and time
   --------------------------------- -}

{-| Get the current date, via the browser's `new Date()` -}
current : Task x Date

{-| Get the current time, via the browser's `Date.now()` -}
now : Task x Time

{- ---------
   Timezones 
   --------- -}

{-| The Javascript API allows you to perform certain operations in terms of
the "local" timezone, or in terms of UTC. So, where we wrap those APIs, we use
this type to let you pick (rather than having separate functions). Of course,
you can use partial application to create separate functions if you like.

Note that this isn't the kind of support that a more sophisticated library
would have for timezones -- it merely wraps what Javascript provides.
-}
type Timezone
    = Local
    | UTC

{-| Javascript's `getTimezoneOffset()`.

This represents what Javascript thinks is the offset between UTC and local time,
for the specified date. It can differ from date to date depending on whether
daylight savings time is in effect on that date.

Note that this is in units of `Time`, so you can scale via `Time.inMinutes` etc.
-}
timezoneOffset : Date -> Time

{- -------------------
   The parts of a date 
   ------------------- -}

{-| The parts of a date.

Note that (as in the Javascript APIs) the month is 0-based, with January = 0.
-}
type alias Parts =
    { year : Int
    , month : Int
    , day : Int
    , hour : Int
    , minute : Int
    , second : Int
    , millisecond : Int
    }

{-| Construct a `Date` from the provided parts, using the specified timezone.

For `Local`, this uses `new Date(...)`.

For `UTC`, this uses `new Date(Date.UTC(...))`.
-}
fromParts : Timezone -> Parts -> Date

{-| Break a `Date` up into its parts, using the specified timezone.

For `Local`, this uses `getFullYear()`, `getMonth()`, etc.

For `UTC`, this uses `getUTCFullYear()`, `getUTCMonth()`, etc.
-}
toParts : Timezone -> Date -> Parts

{-| Get the day of the week corresopnding to a `Date`.

This is handled separately from `Parts` because it is not symmetrical --
it makes no sense for there to be a constructor based on this.
-}
dayOfWeek : Timezone -> Date -> Date.Day

{-| Converts from Javascript's 0-based months (where January = 0) to`Date.Month`. -}
toMonth : Int -> Date.Month

{-| Converts from `Date.Month` to Javascript's 0-based months (where January = 0). -}
fromMonth : Date.Month -> Int

{-| Converts from Javascript's 0-based days (where Sunday = 0) to`Date.Day`. -}
toDay : Int -> Date.Day

{-| Converts from `Date.Day` to Javascript's 0-based days (where Sunday = 0). -}
fromDay : Date.Day -> Int

{- ---------------
   Date arithmetic
   --------------- -}

{-| Offset the `Date` by the supplied `Time` (i.e. positive values offset into
the future, and negative values into the past).

You can use `day`, `week`, `Time.minute`, etc. to scale. However, that won't
always do what you actually want, since the values are treated as durations,
rather than human-oriented intervals. For instance, `offsetTime (365 * day)
date` will advance the date by 365 days. However, if a leap year is involved,
the resulting date might be a different day of the year. If you actually want
the same day in the next year, then use `offsetYear` instead.
-}
offsetTime : Time -> Date -> Date

{-| Offset the `Date` by the specified number of years (forward or backward),
using Javascript's `setFullYear()` and `getFullYear()` (or `getUTCFullYear()`
and `setUTCFullYear`).

Leap years are handled by the underlying Javascript APIs as follows:

* If the supplied date is February 29, and the target year has no February 29,
  then you'll end up with March 1 in the target year. (Arguably, you might
  prefer February 28, but I'm not sure there is a clearly correct answer).

* If the supplied date is February 29, and the target year also has a February
  29, then you'll end up with February 29.

* The year is interpreted in terms of either the local timezone or UTC, according
  to what you specify. I think the only case in which this could make a
  difference is in determining whether it is February 29.

* If the offset "crosses" a leap day, then you'll end up with the "same" day in
  the target year ... for instance, `offsetYear 1` will sometimes move 365
  days and sometimes 366 days, depending on whether a leap year is involved.

A more sophisticated module might deal with these cases a little differently.
-}
offsetYear : Timezone -> Int -> Date -> Date

{-| Offset the `Date` by the specified number of months (forward or backward),
using Javascript's `setMonth()` and `getMonth()` (or `setUTCMonth()` and
`getUTCMonth()`).

Here are a few notes about the underlying Javascript implementation:

* Overflow and underflow basically do the right thing. That is, if you end up
  with negative numbers, the year is decremented, and if you end up with
  numbers past 11, the year is incremented. (Remember that Javascript months
  are 0-based). And, in either case, the month is set to something between
  0 and 11.

* Dates at the beginning of the month are handled as you might expect. For
  instance, adding 1 month to January 1 produces February 1, and adding 1 month
  to February 1 produces March 1. Thus, the actual number of days added can vary,
  depending on the length of the month.

* However, dates at the end of the month are handled in a way that could seem
  odd. For instance, adding 1 month to August 31 produces October 1 ... were
  you expecting September 30? That would probably be more useful, and a more
  sophisticated library might arrange for that.

* Note that the date is interpreted according to either the local timezone or UTC,
  as you specify. In some cases, that will affect whether the date is
  considered to be the last day of the month, or the first day of the next
  month, which will in turn affect whether the "end of month" anomaly is
  triggered.
-}
offsetMonth : Timezone -> Int -> Date -> Date

{- ---------------------------
   Some additional time scales
   --------------------------- -}

{-| A convenience for arithmetic, analogous to `Time.hour`, `Time.minute`, etc. -}
day : Time

{-| A convenience for arithmetic, analogous to `Time.inHours`, `Time.inMinutes`, etc. -}
inDays : Time -> Float

{-| A convenience for arithmetic, analogous to `Time.hour`, `Time.minute`, etc. -}
week : Time

{-| A convenience for arithmetic, analogous to `Time.inHours`, `Time.inMinutes`, etc. -}
inWeeks : Time -> Float

{- ------------------
   String conversions
   ------------------ -}

{-| The browser's `toDateString()` -}
dateString : Date -> String

{-| The browser's `toTimeString()` -}
timeString : Date -> String

{-| The browser's `toISOString()` -}
isoString : Date -> String

{-| The browser's `toUTCString()` -}
utcString : Date -> String
```

***See also***

**`new Date(String)`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.fromString` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`new Date(Number)`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.fromTime` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`getDate()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.day` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest),
or `toParts Local >> .day`

**`getDay()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.dayOfWeek` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest),
or `dayOfWeek Local`

**`getFullYear()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.year` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest),
or `toParts Local >> .year`

**`getHours()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.hour` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest),
or `toParts Local >> .hour`

**`getMilliseconds()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.millisecond` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest),
or `toParts Local >> .millisecond`

**`getMinutes()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.minute` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest),
or `toParts Local >> .minute`

**`getMonth()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.month` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest),
or `toParts Local >> .month`

**`getSeconds()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.second` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest),
or `toParts Local >> .second`

**`getTime()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.toTime` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`getUTCDate()`, `getUTCFullYear()`, `getUTCHours()`, `getUTCMilliseconds()`,
`getUTCMinutes()`, `getUTCMonth()`, `getUTCSeconds()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `toParts UTC`, and then pick out whichever things you need from the
resulting `Parts`.

**`getUTCDay()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `dayOfWeek UTC`

**`parse()`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Date.fromString` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`setDate()`, `setDay()`, `setFullYear()`, `setHours()`, `setMilliseconds()`,
`setMinutes()`, `setMonth()`, `setSeconds()`**

&nbsp; &nbsp; &nbsp; &nbsp;
What I would suggest is

* Use `toParts Local`
* Update whatever fields you with to update
* Use `fromParts Local` to create a new `Date`

Alternatively, in some scenarios you could use `offsetYear Local`, `offsetMonth Local` or `offsetTime`.

**`setUTCDate()`, `setUTCDay()`, `setUTCFullYear()`, `setUTCHours()`, `setUTCMilliseconds()`,
`setUTCMinutes()`, `setUTCMonth()`, `setUTCSeconds()`**

&nbsp; &nbsp; &nbsp; &nbsp;
What I would suggest is

* Use `toParts UTC`
* Update whatever fields you with to update
* Use `fromParts UTC` to create a new `Date`

Alternatively, in some scenarios you could use `offsetYear UTC`, `offsetMonth UTC` or `offsetTime`.

**`toLocaleString()`, `toLocaleDateString()`, `toLocaleTimeString()`**

&nbsp; &nbsp; &nbsp; &nbsp;
These aren't supported by Safari, so I've left them out for the moment.


------------

### WebAPI.Document

See Mozilla documentation for the
[`Document` object](https://developer.mozilla.org/en-US/docs/Web/API/Document).

Since the browser's `document` object has so many facilities attached, I've split some of
them up into individual modules -- see below for the cross-references.

TODO: Finish going through the `document` API.

```elm
module WebAPI.Document where

{-| Possible values for the browser's `document.readyState` -}
type ReadyState
    = Loading
    | Interactive
    | Complete

{-| A `Signal` of changes to the browser's `document.readyState` -}
readyState : Signal ReadyState

{-| A task which, when executed, succeeds with the value of the browser's
`document.readyState`.
-}
getReadyState : Task x ReadyState

{-| A task which, when executed, succeeds with the value of `document.title`. -}
getTitle : Task x String

{-| A task which, when executed, sets the value of `document.title` to the
supplied `String`.
-}
setTitle : String -> Task x () 
```

***See also***

**`cookie`**

&nbsp; &nbsp; &nbsp; &nbsp;
See [WebAPI.Cookie](#webapicookie)


----------

### WebAPI.Intl

TODO. Note that Safari doesn't support this, so it would need a
[polyfill](https://www.npmjs.com/package/intl).

See [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl).


----------

### WebAPI.JSON

Generally speaking, JSON is handled by the
[`Json.Decode`](http://package.elm-lang.org/packages/elm-lang/core/2.1.0/Json-Decode) and
[`Json.Encode`](http://package.elm-lang.org/packages/elm-lang/core/2.1.0/Json-Encode)
modules in elm-lang/core.

TODO: Check if anything is missing.

See [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON).


----------

### WebAPI.Location

See the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/Location).

Note that there is a `Signal`-oriented library for location-related things at
[TheSeamau5/elm-history](http://package.elm-lang.org/packages/TheSeamau5/elm-history/latest).

```elm
module WebAPI.Location where

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

{-| Reloads the page from the current URL. -}
reload : Source -> Task String ()

{-| Whether to force `reload` to use the server, or allow the cache. -}
type Source
    = ForceServer
    | AllowCache
```

***See also***

**`assign`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `setPath` from
[TheSeamau5/elm-history](http://package.elm-lang.org/packages/TheSeamau5/elm-history/latest).

**`replace`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `replacePath` from
[TheSeamau5/elm-history](http://package.elm-lang.org/packages/TheSeamau5/elm-history/latest).


----------

### WebAPI.Math

See the Mozilla documentation for the
[Math object](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math).
Note that things marked "experimental" there have been omitted here.

```elm
module WebAPI.Math where

{-| Returns E to the power of x, where x is the argument, and E is Euler's
constant (2.718…), the base of the natural logarithm.
-}
exp : number -> Float

{-| Natural logarithm of 2, approximately 0.693. -}
ln2 : Float

{-| Natural logarithm of 10, approximately 2.303. -}
ln10 : Float

{-| Returns the natural logarithm (log e, also ln) of a number. -}
log : number -> Float

{-| Base 2 logarithm of E, approximately 1.443. -}
log2e : Float

{-| Base 10 logarithm of E, approximately 0.434. -}
log10e : Float

{-| Returns a pseudo-random number between 0 and 1.

Note that there is a more sophisticated implementation of `Random` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).
However, this may sometimes be useful if you're in a `Task` context anyway.
-}
random : Task x Float

{-| Square root of 1/2; equivalently, 1 over the square root of 2,
approximately 0.707.
-}
sqrt1_2 : Float

{-| Square root of 2, approximately 1.414. -}
sqrt2 : Float
```

***See also***

**`abs`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.abs` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`acos`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.acos` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`asin`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.asin` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`atan`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.atan` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`atan2`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.atan2` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`ceil`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.ceiling` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`cos`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.cos` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`E`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.e` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`floor`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.floor` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`max`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `List.maximum` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`min`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `List.minimum` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`PI`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.pi` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`pow`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.(^)` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`round`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.round` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`sin`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.sin` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`sqrt`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.sqrt` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`tan`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.tan` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).


----------

### WebAPI.Number

See the Mozilla documentation for the
[Number object](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number).
Note that things marked "experimental" there have been omitted here.

```elm
module WebAPI.Number where

{-| The largest positive representable number. -}
maxValue : Float

{-| The smallest positive representable number - that is, the positive number
closest to zero (without actually being zero).
-}
minValue : Float

{-| Special "not a number" value. -}
nan : Float

{-| Special value representing negative infinity; returned on overflow. -}
negativeInfinity : Float

{-| Special value representing infinity; returned on overflow. -}
positiveInfinity : Float

{-| A string representing the provided number in exponential notation. -}
toExponential : number -> String

{-| Either a string representing the second parameter in exponential notation,
with the requested number of digits after the decimal point (first parameter),
or an error. An error should not occur if the requested number of digits is
between 0 and 20.
-}
toExponentialDigits : Int -> number -> Result String String

{-| A string representing the second parameter in exponential notation,
with the requested number of digits after the decimal point (first parameter).
The number of digits will be limited to between 0 and 20.
-}
safeExponentialDigits : Int -> number -> String

{-| A string representing the provided number in fixed-point notation. -}
toFixed : number -> String

{-| Either a string representing the second parameter in fixed-point notation,
with the requested number of digits after the decimal point (first parameter),
or an error. An error should not occur if the requested number of digits is
between 0 and 20.

Note that Firefox returns `Ok 0` rather than an `Error` for a negative number
of requested digits.
-}
toFixedDigits : Int -> number -> Result String String

{-| A string representing the second parameter in fixed-point notation,
with the requested number of digits after the decimal point (first parameter).
The number of digits will be limited to between 0 and 20.
-}
safeFixedDigits : Int -> number -> String

{-| Either a string representing the second parameter in fixed-point or
exponential notation, rounded to the requested number of significant digits
(first parameter), or an error. An error should not occur if the requested
number of digits is between 0 and 20.
-}
toPrecisionDigits : Int -> number -> Result String String

{-| A string representing the second parameter in fixed-point or exponential
notation, with the requested number of significant digits (first parameter).
The number of digits will be limited to between 1 and 20.
-}
safePrecisionDigits : Int -> number -> String

{-| Either a string representing the second parameter using the requested base
(first parameter), or an error. An error should not occur if the requested base
is between 2 and 36.
-}
toStringUsingBase : Int -> number -> Result String String

{-| A string representing the second parameter, using the requested base
(first parameter).  The requested base will be limited to between 2 and 36.
-}
safeStringUsingBase : Int -> number -> String

```

***See also***

**`toLocaleString`**

&nbsp; &nbsp; &nbsp; &nbsp;
Not implemented for the moment, since localization requires some thought.


----------

### WebAPI.RegExp

Generally speaking, regular expressions are handled by the
[`Regex` module](http://package.elm-lang.org/packages/elm-lang/core/2.1.0/Regex)
in elm-lang/core.

TODO: Check if anything is missing.

See [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp).


----------

### WebAPI.Screen

See [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/Screen).

```elm
module WebAPI.Screen where

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

This is a `Task` because, in multi-monitor setups, the result depends on which
screen the browser window is in. So, it is not necessarily a constant.
-}
screen : Task x Screen

{-| A tuple of `(window.screenX, window.screenY)`.

The first value is the horizontal distance, in CSS pixels, of the left border
of the user's browser from the left side of the screen.

The second value is the vertical distance, in CSS pixels, of the top border of
the user's browser from the top edge of the screen.
-}
screenXY : Task x (Int, Int)
```


----------

### WebAPI.Storage

See [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/Storage),
and the [WhatWG documentation](https://html.spec.whatwg.org/multipage/webstorage.html).

There is a more sophisticated `Storage` module available at
[TheSeamau5/elm-storage](https://github.com/TheSeamau5/elm-storage).

Note that we're essentially assuming that `window.localStorage` and
`window.sessionStorage` are, in fact, available. We could account for them
possibly not being available by using a `Maybe` type.

```elm
module WebAPI.Storage where

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

{-| The browser's `sessionStorage` area. -}
session : Storage

{- -----
   Tasks
   ----- -}

{-| A task which, when executed, determines the number of items stored in the
storage area.
-}
length : Storage -> Task x Int

{-| A task which, when executed, determines the name of the key at the given
index (zero-based).
-}
key : Storage -> Int -> Task x (Maybe Key)

{-| A task which, when executed, gets the value at the given key. -}
get : Storage -> Key -> Task x (Maybe Value)

{-| A task which, when executed, sets the value at the given key, or fails with
an error message.
-}
set : Storage -> Key -> NewValue -> Task String ()

{-| A task which, when executed, removes the item with the given key. -}
remove : Storage -> Key -> Task x ()

{-| A task which, when executed, removes all items. -}
clear : Storage -> Task x ()

{- ------
   Events
   ------ -}

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
```


----------

### WebAPI.String

Generally speaking, strings are dealt with by the
[`String` module](http://package.elm-lang.org/packages/elm-lang/core/2.1.0/String)
in elm-lang/core.

TODO: Check if anything is missing.

See [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String).


----------

### WebAPI.Window

See Mozilla documentation for the
[`Window` object](https://developer.mozilla.org/en-US/docs/Web/API/Window),
and for
[function properties](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects#Function_properties).

Since the browser's `window` object has so many facilities attached, I've typically split
them up into individual modules -- see below for the cross-references.

TODO: Finish going through the `window` API.

```elm
module WebAPI.Window where

{-| The browser's `window.alert()` function. -}
alert : String -> Task x ()

{-| The browser's `window.confirm()` function.

The task will succeed if the user confirms, and fail if the user cancels.
-}
confirm : String -> Task () ()

{-| The browser's `window.prompt()` function.

The first parameter is a message, and the second parameter is a default
response.

The task will succeed with the user's response, or fail if the user cancels or
enters blank text.
-}
prompt : String -> String -> Task () String
```

***See also***

**`cancelAnimationFrame`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use [`WebAPI.AnimationFrame`](#webapianimationframe)

**`decodeURI`**

&nbsp; &nbsp; &nbsp; &nbsp;
Not implemented, since you will generally want `decodeURIComponent` instead.

**`decodeURIComponent`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Http.uriDecode` from
[evancz/elm-http](http://package.elm-lang.org/packages/evancz/elm-http/latest).

**`encodeURI`**

&nbsp; &nbsp; &nbsp; &nbsp;
Not implemented, since you will generally want `encodeURIComponent` instead.

**`encodeURIComponent`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Http.uriEncode` from
[evancz/elm-http](http://package.elm-lang.org/packages/evancz/elm-http/latest).

**`eval`**

&nbsp; &nbsp; &nbsp; &nbsp;
Not implemented, since it is an abomination.

**`history`**

&nbsp; &nbsp; &nbsp; &nbsp;
See [TheSeamau5/elm-history](http://package.elm-lang.org/packages/TheSeamau5/elm-history/latest)

**`innerHeight`, `innerWidth`**

&nbsp; &nbsp; &nbsp; &nbsp;
See `Window.dimensions` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`isFinite`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `not Basics.isInfinite` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest)
(i.e. with the sense reversed).

**`isNan`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Basics.isNan` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`localStorage`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use [`WebAPI.Storage.localStorage`](#webapistorage)

**`location`**

&nbsp; &nbsp; &nbsp; &nbsp;
For a `Signal`-oriented approach to things you might do with `window.location`, see
[TheSeamau5/elm-history](http://package.elm-lang.org/packages/TheSeamau5/elm-history/latest).
For some additional `Task`-oriented approaches, see
[`WebAPI.Location`](#webapilocation).

**`parseFloat`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `String.toFloat` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`parseInt`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `String.toInt` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

**`requestAnimationFrame`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use [`WebAPI.AnimationFrame`](#webapianimationframe)

**`setInterval`**

&nbsp; &nbsp; &nbsp; &nbsp;
Consider `Time.fps` (or its variants) from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest),
or `AnimationFrame.frame` (or its variants) from
[jwmerrill/elm-animation-frame](http://package.elm-lang.org/packages/jwmerrill/elm-animation-frame/latest),
or its variants, or `Effects.tick` from
[evancz/elm-effects](http://package.elm-lang.org/packages/evancz/elm-effects/latest).

**`setTimeout`**

&nbsp; &nbsp; &nbsp; &nbsp;
Use `Task.sleep` from
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest),
and then apply an `andThen` to do something after sleeping.

**`scroll`, `scrollBy`, `scrollTo`, `scrollX`, `scrollY`**

&nbsp; &nbsp; &nbsp; &nbsp;
There are a few puzzles about how to best adapt these for Elm, so I'm not sure
a simplistic approach would be best -- a module that thought through scrolling
in an Elm context would probably be better.

**`screen`**

&nbsp; &nbsp; &nbsp; &nbsp;
See [`WebAPI.Screen.screen`](#webapiscreen).

**`screenX`, `screenY`**

&nbsp; &nbsp; &nbsp; &nbsp;
See [`WebAPI.Screen.screenXY`](#webapiscreen).

**`sessionStorage`**

&nbsp; &nbsp; &nbsp; &nbsp;
See [`WebAPI.Storage.sessionStorage`](#webapistorage)


