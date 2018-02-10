module Parser.Internal exposing (Parser, Status(..), State)


type alias Parser problem value =
    State -> Status problem value


type Status problem value
    = Pass State value
    | Fail State problem


type alias State =
    { source : String
    , offset : Int
    , row : Int
    , col : Int
    }
