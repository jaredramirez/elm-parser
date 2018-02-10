# Elm Parser

> Basic parser combinator library for Elm

## Usage

* Install with `elm-package install jaredramirez/elm-parser`
* Import and use!

```
module Sample exposing (..)

import Parser exposing (Parser, (|=), (|*))
import Parser.Char as Char
import Parser.Number as Number


tuple : Parser ( Int, Int )
tuple =
    Parser.parse (\x y -> ( x, y ))
        |* Char.char '('
        |= Number.naturalNumber
        |* Char.char ','
        |= Number.naturalNumber
        |* Char.char ')'

run1 =
  Parser.run tuple "(3,3)"

run2 =
  Parser.run tuple "(35)"
```

`run1` will produce the value:

```
Ok (3,3)
```

`run2` will produce the value:

```
Err
    ( { source = "(35)"
      , offset = 3
      , row = 1
      , col = 4
      }
    , ExpectedSymbol ","
    )
```

In the `run2` example, you are givin the `state` of the parser at the moment of failure and the `Problem` with the parse operatin. It's up to you to take action in the event of a failure.

You can look all the possible types of `Problem`'s [here](https://github.com/jaredramirez/elm-parser/blob/master/src/Parser.elm#L66)

## Other notes

* The primary thing of interest in this package is `Parser.Html`
* This package was written primary as a learning expereince for me

## Thanks

A big thanks to the following, as they taught me alot about parsers in a functional language and are great resources.
\*\*\*\* http://www.cs.nott.ac.uk/~pszgmh/monparsing.pdf

* https://github.com/elm-tools/parser
