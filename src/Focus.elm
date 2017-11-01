module Focus
    exposing
        ( Property
        , property
        , Node
        , element
        , text
        , Crumb
        , crumb
        , Focus
        , focus
        , shiftUp
        , shiftDownToIndex
        , remove
        , replace
        )

import Either exposing (Either(Right, Left))
import List.Extra exposing (splitAt)


type alias EitherS a =
    Either String a


type alias Name =
    String


type alias Props =
    List Property


type alias Children =
    List Node


type Property a
    = Property Name a


type Node
    = Element Name Props Children
    | Text String


type Crumb
    = Crumb Name Props (List Node) (List Node)


type alias Focus =
    ( Node, List Crumb )



-- Constructors


property : Name -> a -> Property a
property =
    Property


element : Name -> Props -> Children -> Node
element =
    Element


text : Name -> Node
text =
    Text


crumb : Name -> Props -> List Node -> List Node -> Crumb
crumb =
    Crumb



-- Interactions


focus : Node -> Focus
focus n =
    ( n, [] )


shiftUp : Focus -> EitherS Focus
shiftUp ( node, crumbs ) =
    case crumbs of
        (Crumb prevName prevProps before after) :: crumbs_ ->
            Right
                ( Element prevName prevProps (before ++ [ node ] ++ after)
                , crumbs_
                )

        [] ->
            Left "Cannot shift up from root"


shiftDownToIndex : Int -> Focus -> EitherS Focus
shiftDownToIndex index ( node, crumbs ) =
    case node of
        Text _ ->
            Left "Cannot shift down from a 'Text' Node"

        Element name props children ->
            let
                splitChildren =
                    splitAt index children
            in
                case splitChildren of
                    ( before, selected :: after ) ->
                        Right
                            ( selected
                            , Crumb name props before after :: crumbs
                            )

                    _ ->
                        Left "Index is out of bounds."


remove : Focus -> EitherS Focus
remove ( node, crumbs ) =
    case crumbs of
        (Crumb prevName prevProps before after) :: crumbs_ ->
            Right
                ( Element prevName prevProps (before ++ after)
                , crumbs_
                )

        [] ->
            Left "Cannot remove root node."


replace : Node -> Focus -> Focus
replace newNode ( _, crumbs ) =
    ( newNode, crumbs )
