module Parser.Char exposing (..)

{-| Pre-made parsers and helpers to create parsers for characters

@docs charCustomError, char, digit, lower, upper, letter, alphanumeric, space, blankspace, newLine, tab

-}

import Char
import Parser as P exposing (Parser, Problem(..))


{-| Parsers a single character, if it fails it uses the provided problem.
You'll usually want to use `char` (see below)

This is Useful when you want to descript more detail about a what you were
expecting, or when you want to express something in more natural language like:

    "expected a space"

    instead of `char`s default of

    "expected \" \""

-}
charCustomError : Char -> Problem -> Parser Char
charCustomError c problem =
    P.satisfy ((==) c) problem


{-| Parsers a single character, if it fails with a default ExpectedSymbol problem
-}
char : Char -> Parser Char
char c =
    charCustomError c (ExpectedSymbol <| String.fromChar c)


{-| Digit character parser
-}
digit : Parser Char
digit =
    P.satisfy Char.isDigit (ExpectedSymbol "digit")


{-| Lowercase character parser
-}
lower : Parser Char
lower =
    P.satisfy Char.isLower (ExpectedSymbol "lowercase letter")


{-| Lowercase character parser
-}
upper : Parser Char
upper =
    P.satisfy Char.isUpper (ExpectedSymbol "uppercase letter")


{-| Parse a lowercase character parser
-}
letter : Parser Char
letter =
    P.oneOf [ lower, upper ]


{-| Parse an alphanumeric character
-}
alphanumeric : Parser Char
alphanumeric =
    P.oneOf [ upper, lower, digit ]


{-| Parse an space character
-}
space : Parser Char
space =
    charCustomError ' ' (ExpectedSymbol "space")


{-| Parse an tab character
-}
tab : Parser Char
tab =
    charCustomError '\t' (ExpectedSymbol "tab")


{-| Parse an newline character
-}
newLine : Parser Char
newLine =
    charCustomError '\n' (ExpectedSymbol "newline")


{-| Parse an space, tab, or newline character
-}
blankspace : Parser Char
blankspace =
    P.oneOf [ space, tab, newLine ]
