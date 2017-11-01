module Parser.String exposing (string, word)

import Parser as P exposing (Parser, Problem(..), (|=), (|*))
import Parser.Char as PChar
import Parser.Combinator as PComb
import String


{-| Like `oneOrMore`, but convets the resulting list of characters to a string
-}
string : Parser Char -> Parser String
string parser =
    P.succeed String.fromList
        |= PComb.oneOrMore parser


{-| Parse an exact word
-}
word : String -> Parser String
word s =
    wordHelper s s


{-| Helper for word
-}
wordHelper : String -> String -> Parser String
wordHelper base s =
    case String.uncons s of
        Just ( c, subS ) ->
            P.succeed String.cons
                |= PChar.charCustomError c
                    (Bad <|
                        "In the word '"
                            ++ base
                            ++ "', expected '"
                            ++ (String.fromChar c)
                            ++ "'"
                    )
                |= wordHelper base subS

        Nothing ->
            P.succeed ""
