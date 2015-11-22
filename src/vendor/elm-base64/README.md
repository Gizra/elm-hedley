Elm-Base64
========

A base 64 encoding and decoding library for Elm. At the moment it only supports
these Ascii characters :

``!\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~``

## Adding to project

Until the package is added to the elm repository you need to copy the
elm files to your elm base source folder.

```
wget https://raw.githubusercontent.com/truqu/elm-base64/master/Ascii.elm
wget https://raw.githubusercontent.com/truqu/elm-base64/master/Base64.elm
wget https://raw.githubusercontent.com/truqu/elm-base64/master/BitList.elm
```

## Using

Add the import to the elm module where you want to do some base64 en- or decoding.

```elm
import Base64
```

To decode a String use

```elm
decode : String -> Result String String
decode encodedString = Base64.decode encodedString
```

To encode a String use

```elm
encode : String -> Result String String
encode regularString = Base64.encode regularString
```


## Building Elm-Base64

To build the project you need to have cabal (>=1.18) installed. To setup the
development environment you can run

``make deps``

This installs the correct elm version in a sandbox in the project folder
(.cabal-sandbox) and downloads the dependencies.

To run the tests

``make test``

To build the project

``make build``
