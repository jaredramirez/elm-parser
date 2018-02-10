module Parser.Html exposing (..)

import Lazy
import String
import Dict exposing (Dict)
import Parser as P exposing (Parser, Problem(..), Status(..), (|=), (|*))
import Parser.Char
    exposing
        ( charCustomError
        , char
        , alphanumeric
        , space
        , lower
        , letter
        , blankspace
        )
import Parser.String exposing (string)
import Parser.Combinator exposing (zeroOrMore, oneOrMore)


-- TYPES


type Node
    = Element Name Properties Children
    | Text String


type alias Name =
    String


type alias Children =
    List Node


type alias Properties =
    Dict String String


type alias Property =
    ( String, String )



-- OPEN TAG


property : Parser Property
property =
    P.succeed (\k v -> ( k, v ))
        |= (string lower)
        |* (charCustomError '=' (ExpectedSymbol "equals"))
        |* (charCustomError '"' (ExpectedSymbol "double quote"))
        |= (string alphanumeric)
        |* (charCustomError '"' (ExpectedSymbol "double quote"))


properties : Parser Properties
properties =
    P.map (Dict.fromList) <|
        zeroOrMore <|
            P.succeed identity
                |* zeroOrMore space
                |= property
                |* zeroOrMore space


openTag : Parser ( Name, Properties )
openTag =
    P.succeed (\n p -> ( n, p ))
        |* char '<'
        |= string letter
        |= properties
        |* charCustomError
            '>'
            (BadOneOf
                [ Bad "I was expecting a property"
                , ExpectedSymbol ">"
                ]
            )



-- CLOSE TAG


closeTag : Parser String
closeTag =
    P.succeed identity
        |* char '<'
        |* char '/'
        |* zeroOrMore space
        |= string lower
        |* zeroOrMore space
        |* char '>'



-- TEXT NODE


textNode : Parser Node
textNode =
    P.succeed identity
        |* zeroOrMore blankspace
        |= P.map (\chars -> Text <| String.fromList chars) (oneOrMore alphanumeric)
        |* zeroOrMore blankspace



-- ELEMENT NODE


checkTagNames : ( Name, Properties, Children, String ) -> Parser Node
checkTagNames ( openName, props, children, closeName ) =
    if openName == closeName then
        P.succeed <| Element openName props children
    else
        P.fail <| Bad "I was expecting html element tag names to match"


parseElement : Parser ( Name, Properties, Children, Name )
parseElement =
    P.succeed
        (\( open, props ) children close ->
            ( open, props, children, close )
        )
        |= openTag
        |* zeroOrMore blankspace
        |= (zeroOrMore <| P.oneOfBacktrack [ textNode, elementNode ])
        |* zeroOrMore blankspace
        |= closeTag


elementNode : Parser Node
elementNode =
    P.succeed identity
        |* zeroOrMore blankspace
        |= P.andThen checkTagNames (P.lazy <| \() -> parseElement)
        |* zeroOrMore blankspace
