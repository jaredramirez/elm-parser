module Parser.Number exposing (naturalNumber, int, float)

{-| Pre-made parsers and helpers to create parsers for numbers

@docs naturalNumber, int, float

-}

import Char
import String
import Misc
import Parser as P exposing (Parser, Problem(..), (|=), (|*))
import Parser.Internal exposing (Status(..))
import Parser.Char as PChar
import Parser.Combinator as PComb


{-| Parse a natural number
-}
naturalNumber : Parser Int
naturalNumber =
    let
        op : Int -> Int -> Int
        op m n =
            10 * m + n

        eval : List Char -> Maybe Int
        eval chars =
            Misc.foldl1 op <|
                List.map (\c -> (Char.toCode c) - (Char.toCode '0')) chars
    in
        P.andThen
            (\digits ->
                case eval digits of
                    Just int ->
                        P.succeed int

                    Nothing ->
                        P.fail (Bad "naturalNumber interal error")
            )
            (PComb.oneOrMore PChar.digit)


{-| Parse an number, including positive and negative numbers
-}
int : Parser Int
int =
    \({ source } as state) ->
        let
            ( state_, func ) =
                case PChar.char '-' state of
                    Pass nextState c ->
                        ( nextState, negate )

                    Fail _ _ ->
                        ( state, identity )
        in
            (P.andThen (\num -> P.succeed (func num)) naturalNumber) state_


{-| Parse a float
-}
float : Parser Float
float =
    let
        failPlaceholder =
            ' '

        result =
            P.succeed
                (\integer digits ->
                    String.toFloat <|
                        (toString integer)
                            ++ "."
                            ++ (toString digits)
                )
                |= int
                |= P.andThen
                    (\val ->
                        if val == failPlaceholder then
                            P.succeed 0
                        else
                            naturalNumber
                    )
                    (P.oneOf [ PChar.char '.', P.succeed failPlaceholder ])
    in
        P.andThen
            (\resultFloat ->
                case resultFloat of
                    Ok float ->
                        P.succeed float

                    Err _ ->
                        P.fail <| Bad "I expected a valid float"
            )
            result
