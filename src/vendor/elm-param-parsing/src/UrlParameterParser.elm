module UrlParameterParser(ParseResult(..), parseSearchString) where

{-| Parse URL parameters. To use this, you'll need to create an input port, pass the search string to Elm,
and then parse them with this function, then that can populate your model.

For instance, in the web page:
```
   var app = Elm.fullscreen(Elm.YourModule,
               { locationSearch: window.location.search });
```
in YourModule.elm:
```
port locationSearch : String
```

Then parse the value of the port - this example discards errors:
```
parameters : Dict String String
parameters =
  case (parseSearchString locationSearch) of
    Error _ -> Dict.empty
    UrlParams dict -> dict
```

Then use that dict when you call your init function that needs the value of the parameter. It'll get a Maybe String.
```
init (Dict.get parameters "customerID")

init : Maybe String -> Model
init maybeID = ...
```

# Method
@docs parseSearchString

# Return type
@docs ParseResult
-}

import Dict exposing (Dict)
import String
import UrlParseUtil exposing (..)

{-| If parsing is successful, you get a UrlParams containing a dictionary of keys to values.
Otherwise, an error string.
If there are no parameters, you'll get an error description.
-}
type ParseResult
  = Error String
  | UrlParams (Dict String String)

{-| Given a search string of the form "?key=value&key2=val2"
parse these into a dictionary of key to value.
-}
parseSearchString : String -> ParseResult
parseSearchString startsWithQuestionMarkThenParams =
  case (String.uncons startsWithQuestionMarkThenParams) of
    Nothing -> Error "No URL params"
    Just ('?', rest) -> parseParams rest
    _ -> Error "No URL params"

parseParams : String -> ParseResult
parseParams stringWithAmpersands =
  let
    eachParam = (String.split "&" stringWithAmpersands)
    eachPair  = List.map (splitAtFirst '=') eachParam
  in
    UrlParams (Dict.fromList eachPair)
