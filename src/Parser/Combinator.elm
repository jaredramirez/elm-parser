module Parser.Combinator exposing (..)

import Parser as P exposing (Parser, (|=), (|*))


{-| Parse 0 or more of a given parser. This parser will always succeed
-}
zeroOrMore : Parser a -> Parser (List a)
zeroOrMore parser =
    P.oneOf
        [ parser
            |> P.andThen
                (\x ->
                    P.andThen (\xs -> P.succeed (x :: xs)) (zeroOrMore parser)
                )
        , (P.succeed [])
        ]


{-| Parse 1 or more of a given parser, otherwise fail
-}
oneOrMore : Parser a -> Parser (List a)
oneOrMore parser =
    P.succeed (::)
        |= parser
        |= (zeroOrMore parser)


{-| Parse exactly `n` times with a given parser
-}
exactly : Int -> Parser a -> Parser (List a)
exactly n parser =
    if n <= 0 then
        P.succeed []
    else
        P.succeed (::)
            |= parser
            |= (exactly (n - 1) parser)


{-| Parse a sequence of values with the values parser, each separated by
the separator parser
-}
separateByOne :
    Parser value
    -> Parser separator
    -> Parser (List value)
separateByOne valueParser separatorParser =
    P.succeed (::)
        |= valueParser
        |= (separateByOneHelper valueParser separatorParser)


{-| Helper for separateByOne
-}
separateByOneHelper :
    Parser value
    -> Parser separator
    -> Parser (List value)
separateByOneHelper valueParser separatorParser =
    zeroOrMore <|
        P.succeed identity
            |* separatorParser
            |= valueParser


{-| Parse a value, with prefix and postfix parsers
-}
brackets :
    Parser open
    -> Parser value
    -> Parser close
    -> Parser value
brackets openParser valueParser closeParser =
    P.succeed identity
        |* openParser
        |= valueParser
        |* closeParser
