# Elm Parameter Parsing

This is an elm library for parsing parameters on the URL.

## To use it

```elm package install jessitron/elm-param-parsing```

To use this, you'll need
to create an input port, pass the search string to Elm, and then parse
them with this function, then that can populate your model.

For instance, in the web page:

    var app = Elm.fullscreen(Elm.YourModule,
               { locationSearch: window.location.search });

in YourModule.elm, declare the port and then parse what comes into it. This example discards errors:

```elm
import Dict exposing (Dict)

port locationSearch : String

parameters : Dict String String
parameters =
  case (parseSearchString locationSearch) of
    Error _ -> Dict.empty
    UrlParams dict -> dict
```

Then use that dict when you call your init function that needs the value
of the parameter.

```elm
init (Dict.get parameters "customerID")

init : Maybe String -> Model
init maybeID = ...
```

## see it in action

The example app is built into this repo.
[source](https://github.com/jessitron/elm-param-parsing/tree/ui);
[result](http://jessitron.github.io/elm-param-parsing)
