# The Elm Architecture Tutorial as a single page app

In order to illustrate how to use
[elm-route-hash](https://github.com/rgrempel/elm-route-hash),
I though it might be useful to take some familiar code and show
how to turn it into a single-page app with bookmarkable URLs
and a working "forward" and "back" button.

What code could be more familiar than the
[Elm Architecture Tutorial](https://github.com/evancz/elm-architecture-tutorial)?
And, the tutorial consists of 8 examples which are each separate pages. So, why
not show how to turn those 8 examples into a single page?

So, what steps did I follow to do this?

## Clean up the original code

*   I copied the 8 examples from the Elm Architecture Tutorial.

*   I renamed the directories to "Example1", "Example2" etc., instead of "1",
    "2", etc., since that made for better module names. (Since all examples
    will now be in a single page, the directory names are part of the module
    name).

*   Then, I changed the module declarations in each file to include the
    directory name. For instance, the declaration of `Counter.elm` in the first
    example changes from `module Counter where` to `module Example1.Counter
    where`. I made the equivalent changes to the existing `import` statements.

*   Then I removed the `README.md` and `elm-package.json` files
    from each example folder. They aren't necessary any longer, since all the
    examples will now be on a single page.

*   I copied `StartApp.elm` from
    [evancz/start-app](https://github.com/evancz/start-app.git), because I
    thought it was necessary to make a small modification to it in order to use
    it with elm-route-hash. **Update**: It turns out that there is a way to
    make this work with an unmodified `StartApp` after all -- see below.

*   I created an `elm-package.json` file at the root of the project.

*   I moved the `assets` directory from each example folder to the root of the
    project.

*   And I created this README -- the very one you are reading right now.

So, none of these were actual code changes -- I just cleaned things up so that
the real work could start.

Note that I hadn't yet removed the individual `Main.elm` files from each example,
because they contain just a little bit of code that needs to be accounted for.
Ultimately, we won't want individual `Main.elm` files, of course.

If you'd like to see the code at this stage,
[here's a link](https://github.com/rgrempel/elm-route-hash/tree/6832fd459db204a4acea8820d6dcfc40b6cbe86f/examples/elm-architecture-tutorial)


## Create the ExampleViewer

Now, to create a single-page app, we'll need something which is aware of all the
potential examples, tracks which one we're looking at, and allows some way
to switch from one to another. Let's call that an `ExampleViewer` ... I've
implemented it in `ExampleViewer.elm`. To see what it does, it's probably
best just to look at the code.

This also required some minor changes in the examples themselves.

Here's a link to the [commit that made the changes](https://github.com/rgrempel/elm-route-hash/commit/cc69752e3622442d245ec8af2868bacf7a24c948)

So, at this stage, we have turned the 8 separate example pages into a single
page app that allows us to navigate from one example to another by clicking.
If you'd like to try out what it was like at this point,
[here's a live page](http://rgrempel.github.io/elm-route-hash/examples/elm-architecture-tutorial/spa.html)

But, we haven't done anything with the URL yet -- the next step is to actually
hook up elm-route-hash.


## Basic use of elm-route-hash

So, the next step is to do a basic implementation of elm-route-hash. What
does this involve?

*   Our `ExampleViewer.elm` needs to implement `delta2update` and
    `location2action`.

*   Our `Main.elm` needs to call `RouteHash.start`

*   We need to make an intermediate `Mailbox Action` to make things work
    with `StartApp`.

To see how I did this, the best thing is to read the code. Here's a
[link to the original commit that made the changes](https://github.com/rgrempel/elm-route-hash/commit/77228f25de1e05f419839ed9f63a51e046f84493).
You can ignore the small change to `StartApp`, because it turns out not to be
necessary -- instead, an intermediate mailbox can be used in the `Main`
module. Here's the
[commit that does that](https://github.com/rgrempel/elm-route-hash/commit/887b03300899600cdebab83522582a7246029d20).

So, what do we have now? Here's the [live page](http://rgrempel.github.io/elm-route-hash/examples/elm-architecture-tutorial/basic.html).

*   Try navigating with the links to each example (like we could do
    at the previous stage). Notice how the URL in the location bar
    changes.

*   After navigating with the links, try using the 'forward' and
    'back' buttons -- see what they do.

*   Navigate to an example, and then hit 'Reload' in the browser
    -- see if something good happens.

*   Try bookmarking one of the examples. Navigate somewhere else,
    and then activate the bookmark.

Isn't this fun? And it wasn't really that hard to do.


## Advanced use of elm-route-hash

A more advanced use of elm-route-hash might dive down into a second (or
further) layer of the app, so that it's not just the current example
that's tracked in the URL, but some additional state at the lower level.

How much of this you want to do is entirely up to you. Generally speaking, you
should only track "view model" state in the URL -- that is, state which affects
how the data appears to the user, rather than state which is part of the
fundamental, permanent data of your app. Otherwise, the back and forward
buttons, bookmarks, etc., will do unexpected things.  I suppose the distinction
here is like the distinction between "GET" requests and "POST" or "PUT"
requests in HTTP. Changing the URL is analogous to a "GET" request, and thus
should not change fundamental state -- it should only change state that affects
something about which part of the app the user is viewing at the moment.

So, depending on how you conceive of that, there isn't necessarily a lot more
in the examples that really qualifies as "view model" state. But, I will
illustrate how to do multiple layers of state anyway, just so you can see how.

Here's a [link to the commit that made these changes](https://github.com/rgrempel/elm-route-hash/commit/b07334fea92214e877b953992a88df428d201013).

So, what do we have now? Here's the [live page](http://rgrempel.github.io/elm-route-hash/examples/elm-architecture-tutorial/advanced.html).

*   Try incrementing an decrementing a counter in Example 1. Look at how the
    URL changes. Try the forward and back buttons. Try bookmarking and
    activating a bookmark. Try reloading a page. In the previous example,
    the examples would reset, whereas now they should maintain state.

*   Try playing with the other examples. I've hooked up most of the state
    with the URL -- it's actually a bit more than I might do in a real app.

So, I hope that helps get you started.
