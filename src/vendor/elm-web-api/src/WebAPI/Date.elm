module WebAPI.Date
    ( current, now
    , Timezone(Local, UTC), timezoneOffset
    , Parts, fromParts, toParts, dayOfWeek
    , toMonth, fromMonth, toDay, fromDay
    , offsetTime, offsetYear, offsetMonth
    , day, inDays
    , week, inWeeks
    , dateString, timeString, isoString, utcString
    ) where


{-| Some additional facilities for the browser's `Date` type, not already
supplied by `Date` and `Time` in
[elm-lang/core](http://package.elm-lang.org/packages/elm-lang/core/latest).

See the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date).

This is intended merely to be a thin wrapper over the Javascript `Date` API.
There is some real complexity in dealing with dates that would benefit from a
more sophisticated library.

# Getting the current date or time

@docs current, now

# Timezones

@docs Timezone, timezoneOffset

# The parts of a date 

@docs Parts, fromParts, toParts, dayOfWeek
@docs toMonth, fromMonth, toDay, fromDay

# Date arithmetic

@docs offsetTime, offsetYear, offsetMonth

# Time scales

In the spirit of `Time.hour`, `Time.inHours`, `Time.second`, `Time.inSeconds`,
`Time.millisecond`, and `Time.inMilliseconds`.

@docs day, inDays, week, inWeeks

# String conversions

@docs dateString, timeString, isoString, utcString
-}


import Date exposing (Date)
import Time exposing (Time)
import Task exposing (Task)
import Debug

import Native.WebAPI.Date


{- --------------------------------- 
   Getting the current date and time
   --------------------------------- -}


{-| Get the current date, via the browser's `new Date()` -}
current : Task x Date
current = Native.WebAPI.Date.current


{-| Get the current time, via the browser's `Date.now()` -}
now : Task x Time
now = Native.WebAPI.Date.now


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
timezoneOffset date =
    (timezoneOffsetInMinutes date) * Time.minute


timezoneOffsetInMinutes : Date -> Float
timezoneOffsetInMinutes = Native.WebAPI.Date.timezoneOffsetInMinutes


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
fromParts zone =
    case zone of
        Local -> fromPartsLocal
        UTC -> fromPartsUtc


fromPartsLocal : Parts -> Date
fromPartsLocal = Native.WebAPI.Date.fromPartsLocal


fromPartsUtc : Parts -> Date
fromPartsUtc = Native.WebAPI.Date.fromPartsUtc


{-| Break a `Date` up into its parts, using the specified timezone.

For `Local`, this uses `getFullYear()`, `getMonth()`, etc.

For `UTC`, this uses `getUTCFullYear()`, `getUTCMonth()`, etc.
-}
toParts : Timezone -> Date -> Parts
toParts zone =
    case zone of
        Local -> toPartsLocal
        UTC -> toPartsUtc


toPartsLocal : Date -> Parts
toPartsLocal = Native.WebAPI.Date.toPartsLocal


toPartsUtc : Date -> Parts
toPartsUtc = Native.WebAPI.Date.toPartsUtc


{-| Get the day of the week corresopnding to a `Date`.

This is handled separately from `Parts` because it is not symmetrical --
it makes no sense for there to be a constructor based on this.
-}
dayOfWeek : Timezone -> Date -> Date.Day
dayOfWeek timezone date =
    case timezone of
        Local ->
            Date.dayOfWeek date

        UTC ->
            toDay (dayOfWeekUTC date)


dayOfWeekUTC : Date -> Int
dayOfWeekUTC = Native.WebAPI.Date.dayOfWeekUTC


{-| Converts from Javascript's 0-based months (where January = 0) to`Date.Month`. -}
toMonth : Int -> Date.Month
toMonth int =
    let
        clamped =
            int `rem` 12

        positive =
            if clamped < 0
                then clamped + 12
                else clamped

    in
        case positive of
            0 -> Date.Jan
            1 -> Date.Feb
            2 -> Date.Mar
            3 -> Date.Apr
            4 -> Date.May
            5 -> Date.Jun
            6 -> Date.Jul
            7 -> Date.Aug
            8 -> Date.Sep
            9 -> Date.Oct
            10 -> Date.Nov
            11 -> Date.Dec
            _ -> Debug.crash "This is unreachable."


{-| Converts from `Date.Month` to Javascript's 0-based months (where January = 0). -}
fromMonth : Date.Month -> Int
fromMonth month =
    case month of
        Date.Jan -> 0
        Date.Feb -> 1
        Date.Mar -> 2
        Date.Apr -> 3
        Date.May -> 4
        Date.Jun -> 5
        Date.Jul -> 6
        Date.Aug -> 7
        Date.Sep -> 8
        Date.Oct -> 9
        Date.Nov -> 10
        Date.Dec -> 11


{-| Converts from Javascript's 0-based days (where Sunday = 0) to`Date.Day`. -}
toDay : Int -> Date.Day
toDay int =
    let
        clamped =
            int `rem` 7

        positive =
            if clamped < 0
                then clamped + 7
                else clamped

    in
        case positive of
            0 -> Date.Sun
            1 -> Date.Mon
            2 -> Date.Tue
            3 -> Date.Wed
            4 -> Date.Thu
            5 -> Date.Fri
            6 -> Date.Sat
            _ -> Debug.crash "This is unreachable."


{-| Converts from `Date.Day` to Javascript's 0-based days (where Sunday = 0). -}
fromDay : Date.Day -> Int
fromDay day =
    case day of
        Date.Sun -> 0
        Date.Mon -> 1
        Date.Tue -> 2
        Date.Wed -> 3
        Date.Thu -> 4
        Date.Fri -> 5
        Date.Sat -> 6


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
offsetTime time date =
    Date.fromTime ((Date.toTime date) + time)


{-| Offset the `Date` by the specified number of years (forward or backward),
using Javascript's `setFullYear()` and `getFullYear()` (or `getUTCFullYear()`
and `setUTCFullYear()`).

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
offsetYear zone =
    case zone of
        Local -> offsetYearLocal 
        UTC -> offsetYearUTC


offsetYearLocal : Int -> Date -> Date
offsetYearLocal = Native.WebAPI.Date.offsetYearLocal


offsetYearUTC : Int -> Date -> Date
offsetYearUTC = Native.WebAPI.Date.offsetYearUTC


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
offsetMonth zone =
    case zone of
        Local -> offsetMonthLocal
        UTC -> offsetMonthUTC


offsetMonthLocal : Int -> Date -> Date
offsetMonthLocal = Native.WebAPI.Date.offsetMonthLocal


offsetMonthUTC : Int -> Date -> Date
offsetMonthUTC = Native.WebAPI.Date.offsetMonthUTC


{- ---------------------------
   Some additional time scales
   --------------------------- -}


{-| A convenience for arithmetic, analogous to `Time.hour`, `Time.minute`, etc. -}
day : Time
day = 24 * Time.hour


{-| A convenience for arithmetic, analogous to `Time.inHours`, `Time.inMinutes`, etc. -}
inDays : Time -> Float
inDays days = days / day


{-| A convenience for arithmetic, analogous to `Time.hour`, `Time.minute`, etc. -}
week : Time
week = 7 * day


{-| A convenience for arithmetic, analogous to `Time.inHours`, `Time.inMinutes`, etc. -}
inWeeks : Time -> Float
inWeeks weeks = weeks / week


{- ------------------
   String conversions
   ------------------ -}


{-| The browser's `toDateString()` -}
dateString : Date -> String
dateString = Native.WebAPI.Date.dateString


{-| The browser's `toTimeString()` -}
timeString : Date -> String
timeString = Native.WebAPI.Date.timeString


{-| The browser's `toISOString()` -}
isoString : Date -> String
isoString = Native.WebAPI.Date.isoString


{-| The browser's `toUTCString()` -}
utcString : Date -> String
utcString = Native.WebAPI.Date.utcString


