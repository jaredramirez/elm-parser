module Parser
    exposing
        ( Parser
        , State
        , Status(..)
        , Problem(..)
        , lazy
        , succeed
        , fail
        , andThen
        , map
        , map2
        , (|=)
        , (|*)
        , oneOf
        , oneOfBacktrack
        , item
        , satisfy
        , run
        )

import Lazy exposing (Lazy)
import String
import List
import Misc


-- TYPES


{-| Parser type
-}
type alias Parser value =
    State -> Status value


{-| Result of a parse operation
-}
type Status result
    = Pass State result
    | Fail State Problem


{-| State that is passed through each parse operation and keeps data about the
operation as it goes.
-}
type alias State =
    { source : String
    , offset : Int
    , row : Int
    , col : Int
    }


{-| Possible errors that can be encountered while parsing
-}
type Problem
    = BadOneOf (List Problem)
    | BadInt
    | Bad String
    | ExpectedSymbol String



-- PRIMATIVES


{-| Lift a value into a successful parse operation
-}
succeed : value -> Parser value
succeed value =
    \state ->
        Pass state value


{-| Fails a parse operation with a problem
-}
fail : Problem -> Parser value
fail problem =
    \state ->
        Fail state problem


{-| Used to declare a parser in an anonymous function, allowing you to defined
resusive grammers
-}
lazy : (() -> Parser value) -> Parser value
lazy wrapper =
    \state ->
        wrapper () <| state



-- MAP


{-| Transform the result of a parser
-}
map : (valueA -> valueB) -> Parser valueA -> Parser valueB
map func parser =
    \state ->
        case parser state of
            Pass nextState value ->
                succeed (func value) nextState

            Fail failState problem ->
                fail problem failState


{-| Transform the reuslt of two parser
-}
map2 :
    (valueA -> valueB -> valueC)
    -> Parser valueA
    -> Parser valueB
    -> Parser valueC
map2 func parserA parserB =
    \state ->
        case parserA state of
            Pass stateA valueA ->
                case parserB stateA of
                    Pass stateB valueB ->
                        succeed (func valueA valueB) stateB

                    Fail failState problem ->
                        fail problem failState

            Fail failState problem ->
                fail problem failState



-- ANDTHEN


{-| Transfrom a parser, based on the result of the previous one
-}
andThen :
    Parser resultA
    -> (resultA -> Parser resultB)
    -> Parser resultB
andThen parser func =
    \state ->
        case parser state of
            Pass nextState result ->
                (func result) nextState

            Fail failState problem ->
                fail problem failState



-- MULTIPLE PARSERS


{-| Test a list of parser on a state, without backtracking if a parser fails.
In the case of

    let
        state =
            { source = "bonasdf"
            , offset = 0
            , row = 0
            , col = 0
            }
    in
        oneOf [word "bonjour", lower] state

The parser will fail because it starts to correctly parse "bonjour", but fails
part way. Becuase there is no backtracking, and does not revert to `lower` after
`word "bonjour" fails.

-}
oneOf : List (Parser result) -> Parser result
oneOf parsers =
    \state ->
        oneOfHelper state parsers []


{-| Helper for oneOf
-}
oneOfHelper :
    State
    -> List (Parser result)
    -> List Problem
    -> Status result
oneOfHelper state parsers problems =
    case parsers of
        [] ->
            fail (BadOneOf <| List.reverse problems) state

        parser :: rest ->
            case parser state of
                (Pass _ _) as status ->
                    status

                (Fail { row, col } problem) as status ->
                    {- Check that this current parser hasn't progressed before
                       attempting the next one
                    -}
                    if state.row == row && state.col == col then
                        oneOfHelper state rest (problem :: problems)
                    else
                        status


{-| Test a list of parser on a state, WITH backtracking if a parser fails. This
means if the first parser fails, it WILL to back to the beginning and try the
next parser
|
-}
oneOfBacktrack : List (Parser result) -> Parser result
oneOfBacktrack parsers =
    \state ->
        oneOfBacktrackHelper state parsers []


{-| Helper for oneOfBacktrack
-}
oneOfBacktrackHelper :
    State
    -> List (Parser result)
    -> List Problem
    -> Status result
oneOfBacktrackHelper state parsers problems =
    case parsers of
        [] ->
            fail (BadOneOf <| List.reverse problems) state

        parser :: rest ->
            case parser state of
                (Pass _ _) as status ->
                    status

                Fail _ problem ->
                    oneOfBacktrackHelper state rest (problem :: problems)



-- BASIC PARSE OPERATIONS


{-| Parses a single character, always successful as long at the offset is valid
-}
item : Parser Char
item =
    \({ source, offset, row, col } as state) ->
        let
            nextOffset =
                offset + 1

            sliver =
                String.uncons <| String.slice offset nextOffset source
        in
            case sliver of
                Just ( c, _ ) ->
                    let
                        ( nextRow, nextCol ) =
                            if c == '\n' then
                                ( row + 1, 0 )
                            else
                                ( row, col + 1 )
                    in
                        succeed c
                            { state
                                | offset = nextOffset
                                , row = nextRow
                                , col = nextCol
                            }

                Nothing ->
                    fail (Bad "I didn't expect the input string to end") state


{-| Tests a the parsed character with the function provided, if it return false,
then fail with the provided problem
-}
satisfy : (Char -> Bool) -> Problem -> Parser Char
satisfy test problem =
    \state ->
        case item state of
            Pass nextState c ->
                if test c then
                    succeed c nextState
                else
                    -- if test fails, keep the original state
                    fail problem state

            Fail failState _ ->
                fail problem failState



-- PIPELINE


{-| Given a parserA that contians a function and parserB that is regular run
both. Apply the result from parserB to the function from parserA
-}
(|=) : Parser (a -> b) -> Parser a -> Parser b
(|=) parserFunc parserArg =
    map2 Misc.applyFunc parserFunc parserArg


{-| Given a parserA and parserB, run both but only keep the result from parserB
-}
(|*) : Parser keep -> Parser ignore -> Parser keep
(|*) parserIgnore parserKeep =
    map2 always parserIgnore parserKeep



-- RUNNER


{-| Wrap a source string into a default state
-}
defaultState : String -> State
defaultState source =
    State source 0 1 1


{-| Wrap a source string into a default state
-}
run : Parser a -> String -> Status a
run parser source =
    parser <| defaultState source
