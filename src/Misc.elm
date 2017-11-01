module Misc exposing (foldl1, applyFunc)


foldl1 : (a -> a -> a) -> List a -> Maybe a
foldl1 f xs =
    let
        op x m =
            Just
                (case m of
                    Nothing ->
                        x

                    Just y ->
                        f y x
                )
    in
        List.foldl op Nothing xs


applyFunc : (a -> b) -> a -> b
applyFunc f a =
    f a
