# elm-route-hash

This is a module for routing single-page-apps in Elm, building on the
[navigation](http://package.elm-lang.org/packages/elm-lang/navigation/latest)
package.

The name of this package reflects the fact that it orginally only worked
with the "hash" portion of the URL. This is no longer true -- you can work with
the full URL if you like.


## Overview

Now, the official [navigation](http://package.elm-lang.org/packages/elm-lang/navigation/latest)
package is a perfectly good solution for what is often called "routing". And
there are a wealth of alternative or complementary packages, such as

* [evancz/url-parser](http://package.elm-lang.org/packages/evancz/url-parser/latest)
* [Bogdanp/elm-combine](http://package.elm-lang.org/packages/Bogdanp/elm-combine/latest)
* [Bogdanp/elm-route](http://package.elm-lang.org/packages/Bogdanp/elm-route/latest)
* [etaque/elm-route-parser](http://package.elm-lang.org/packages/etaque/elm-route-parser/latest)
* [sporto/erl](http://package.elm-lang.org/packages/sporto/erl/latest)

So, what is the point of elm-route-hash?

The particular philosophy of elm-route-hash is that the router should not take
over the design of your app. Instead, you should be able to generate changes
to the URL, and respond to changes to the URL, as a secondary concern.

What does this mean practically? Basically, you have to implement two functions,
which take the following form:

```elm
-- Translate a `Location` object into messages that your app can respond to
-- in its normal `update` function. Called when the `Location` changes due
-- to external action (i.e. a bookmark, clicking on a URL, or typing in the
-- location bar).
location2messages : Location -> List msg

-- Given a change in your app's model, compute what URL ought to be showing
-- in the location bar.
delta2url : model -> model -> Maybe UrlChange
```

If that sounds like a nice API, then read on!


## Routing

What does "routing" mean? Essentially, there are two things which we want to do:

* Map changes in the browser's location to messages our app can respond to.
* Map changes in our app's state to changes in the browser's location.

So, let's think a little more about these two mappings.


### Mapping location changes to messages our app can respond to

In effect, what we're looking for here is something like this:

```elm
Location -> List msg
```

That is, when the location changes (whether because of manually typing in
the location bar, activating a bookmark, or using the 'forward' and 'back'
buttons, etc.), we want to convert that into messages which our app can respond to.

This is similar to the approach taken by the `urlUpdate` function in the official
[navigation](http://package.elm-lang.org/packages/elm-lang/navigation/latest)
package. The difference is that the `urlUpdate` function must actually compute
the response itself -- that is, it must compute the new model and any related
commands. By contrast, elm-route-hash asks you to "translate" the location
change into messages your app's `update` function can already respond to.

The possible advantage of the approach taken by elm-route-hash is that your
url-handling code has a more limited scope. Instead of doing possibly anything,
its work is limited to translating location changes to messages that your
app could respond to even without any URLs being involved. Thus, elm-route-hash
maintains the principle that all changes to the model are done through your
`update` function. It also avoids forcing you to make certain changes via the
URL -- you can always use the equivalent messages instead.


### Mapping changes in the app state to a possible location change

Here, what we are looking for is something like this:

```elm
model -> model -> Maybe UrlUpdate
```

That is, when your app's model changes, we want to possibly generate a command
to change the browser's apparent location.

If you were using the official
[navigation](http://package.elm-lang.org/packages/elm-lang/navigation/latest)
package directly, then changes to the URL are just ordinary commands, that you
compute in the ordinary way. So, what are the possible advantages of the approach
taken by elm-route-hash?

The main advantage is that you can ignore some issues that you might otherwise
want to deal with in one way or another. For instance, what if the new URL
is actually the same as the old URL? You might want to avoid creating a new
history entry. Or, what if the change in the model was actually a response
to a URL change? You wouldn't want to change the URL again, since that would
trigger yet another response, and so on.

Of course, you can solve those issues with your own code. However, if you
use elm-route-hash, you don't have to.


## API

For the detailed API, see the documentation for `RouteUrl` and `RouteHash`.

The `RouteUrl` module is (as of version 2.0) the "primary" module. It gives
you access to the whole `Location` object, and allows you set the path, query
and/or hash, as you wish.

The `RouteHash` module attempts to match the API of version 1.0.x of
elm-route-hash as closely as possible. So, you may find it useful if you
previously used elm-route-hash. Version 1.0.x of elm-route-hash depended on a
kind of manipulation of the signal graph which is no longer possible in Elm
0.17. However, `RouteHash` mimics the way it used to work as much as possible.


