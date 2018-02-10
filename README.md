# Elm Parser

> General purpose parser library for Elm

`elm-package install jaredramirez/elm-parser`

## Usage
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

In the `run2` example, you are givin the `state` of the parser at the moment of failure and the `Problem` with the parse operation.

You can look all the possible values of `Problem`'s [here](https://github.com/jaredramirez/elm-parser/blob/master/src/Parser.elm#L56).

## How it works

Take the parser from the above example.

```
transform : Int -> Int -> ( Int, Int )
transform x y =
    ( x, y )


tuple : Parser ( Int, Int )
tuple =
    Parser.succeed transform
        |* Char.char '('
        |= Number.naturalNumber
        |* Char.char ','
        |= Number.naturalNumber
        |* Char.char ')'
```

First, we create the function `transform` that takes two `Int`s, and puts them in a tuple. Then, in the first line of the `tuple` function, we take the function `transform` and lifting it into a "parser".
In the subsequent parts of the pipline, we are applying parsers to the function `transform`.
If the parser in the pipline begins with

* `|*` it means "run is parser and make sure it is successful, then **throw away** the result".
* `|=` it means "run is parser and make sure it is successful, then **apply** the result to the function".

This relies on partial function application. In this case, `transform` has two arguements, so in our pipeline we must have two `|=` to get a result, otherwise `transform` won't have all of it's arguements applied!

For more on the pipeline parser concept, see [this](https://github.com/elm-tools/parser#parser-pipelines).

You can also use this library to chain parsers with `andThen`. This is generally not as readable and can be more confuisng than pipeline-style parsing. It can be helpeful to have though. Say you only want tuples where the values are equal. That is, `(1,1)` would succeed but `(1,2)` would not.
You can refactor `tuple` it include that functionality easily with `andThen`:

```
tuple : Parser ( Int, Int )
tuple =
    let
        tupleParser =
            Parser.succeed transform
                |* Char.char '('
                |= Number.naturalNumber
                |* Char.char ','
                |= Number.naturalNumber
                |* Char.char ')'
    in
        tupleParser
            |> Parser.andThen
                (\( x, y ) ->
                    if x == y then
                        Parser.succeed ( x, y )
                    else
                        Parser.fail <|
                            Parser.Bad "I expected the values to match"
                )
```

## Thanks

While I wrote all of the code in this package, most of it was heavily influenced/inspired by others (with the exception of `Parser.Html`). This package was written for the purpose of my learning, and I figured I'd publish it for kicks. So, a big thanks to the following as they taught me a lot about parsers in a functional language, and are great resources.

* http://www.cs.nott.ac.uk/~pszgmh/monparsing.pdf
* https://github.com/elm-tools/parser
