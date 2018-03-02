module Game.BoardView exposing (view)

import Css exposing (hex)
import Game.SnakeImages.Heads exposing (..)
import Game.SnakeImages.Tails exposing (..)
import Html.Styled exposing (div)
import Math.Vector2 as V2 exposing (..)
import Svg.Styled as Svg exposing (..)
import Svg.Styled.Attributes as Attrs exposing (..)
import Theme exposing (theme)
import Types exposing (..)


scale : number -> number
scale x =
    x * 100


margin : number
margin =
    20


gridPos : number -> String
gridPos x_ =
    x_ |> scale |> (+) margin |> toString


scaleVec2 : Vec2 -> Vec2
scaleVec2 v =
    vec2
        (v
            |> getX
            |> scale
            |> (+) margin
        )
        (v
            |> getY
            |> scale
            |> (+) margin
        )


gridUnit : number
gridUnit =
    1 |> scale |> (+) (margin * -1)


gridUnitString : String
gridUnitString =
    gridUnit |> toString


gridPathOffset : Float
gridPathOffset =
    (scale 1 / 2) + (margin / 2) + 10


blockPos : Vec2 -> List (Attribute msg)
blockPos v =
    [ v |> getX |> gridPos |> x
    , gridUnitString |> width
    , v |> getY |> gridPos |> y
    , gridUnitString |> height
    ]


square : List (Attribute msg) -> Vec2 -> Svg msg
square attrs point =
    rect (blockPos point ++ attrs) []


circle_ : List (Attribute msg) -> Vec2 -> Svg msg
circle_ attrs v =
    circle
        ([ gridUnit / 2 |> toString |> r
         , v |> getX |> scale |> (+) (gridUnit / 2) |> toString |> cx
         , v |> getY |> scale |> (+) (gridUnit / 2) |> toString |> cy
         ]
            ++ attrs
        )
        []


view : Board -> Html.Styled.Html msg
view board =
    let
        food =
            board.food

        height_ =
            board.height

        width_ =
            board.width

        snakes =
            board.snakes

        deadSnakes =
            board.deadSnakes

        gridPattern =
            "GridPattern" ++ toString board.gameid

        viewBox_ =
            [ 0, 0, scale (width_ + 1), scale (height_ + 1) ]
                |> List.map toString
                |> String.join " "
    in
    svg
        [ viewBox viewBox_
        , css
            [ 1 |> Css.int |> Css.flexGrow ]
        ]
        [ defs []
            [ pattern
                [ id gridPattern
                , x "0"
                , y "0"
                , width (1.0 / toFloat width_ |> toString)
                , height (1.0 / toFloat height_ |> toString)
                ]
                [ square [ fill theme.tile.value, opacity "0.25" ] (vec2 0 0) ]
            ]
        , rect
            [ fill <| "url(#" ++ gridPattern ++ ")"
            , width (width_ |> scale |> toString)
            , height (height_ |> scale |> toString)
            , x "50"
            , y "50"
            ]
            []
        , g
            [ vec2 gridPathOffset gridPathOffset
                |> translate
                |> transform
            , css [ Css.fill theme.food ]
            ]
            (List.map (circle_ []) food)
        , g
            [ vec2 gridPathOffset gridPathOffset
                |> translate
                |> transform
            ]
            (List.concatMap snakeView (snakes ++ deadSnakes))
        ]


type Acc
    = Acc Term Term Vec2 Vec2 (List Vec2)
    | AccFirst Term
    | AccInit


type alias Term =
    { pos : Vec2, dir : Vec2 }


term : Vec2 -> Term
term pos =
    Term pos (vec2 0 0)


term2 : Vec2 -> Vec2 -> Term
term2 a b =
    Term a (sub a b)


alignWithMargin : Term -> Vec2 -> Vec2
alignWithMargin { dir } vec =
    dir
        |> V2.normalize
        |> V2.scale (margin / -52)
        |> add vec


snakeView : Snake -> List (Svg msg)
snakeView record =
    let
        alive =
            case record.death of
                Nothing ->
                    True

                Just _ ->
                    False

        coords =
            record.coords
                |> List.foldl reduce AccInit

        opacityValue =
            case record.death of
                Nothing ->
                    "1.0"

                Just _ ->
                    "0.45"

        reduce : Vec2 -> Acc -> Acc
        reduce current acc =
            case acc of
                AccInit ->
                    AccFirst (term current)

                (AccFirst ({ pos } as term)) as acc ->
                    if pos == current then
                        acc
                    else
                        let
                            start =
                                term2 pos current

                            end =
                                term2 current pos
                        in
                        Acc
                            start
                            end
                            current
                            pos
                            [ alignWithMargin end current
                            , alignWithMargin start pos
                            ]

                (Acc start end prev1 prev2 list) as acc ->
                    if current == prev1 then
                        acc
                    else
                        let
                            end_ =
                                term2 current prev1

                            lastSegment =
                                alignWithMargin end_ current

                            list_ =
                                lastSegment :: prev1 :: List.drop 1 list
                        in
                        Acc start end_ current prev1 list_

        points_ =
            case coords of
                Acc _ _ _ _ list ->
                    list
                        |> List.concatMap (\v -> [ getX v, getY v ])
                        |> List.map (scale >> truncate >> toString)
                        |> String.join " "

                _ ->
                    ""

        polyline_ =
            case coords of
                Acc _ _ _ _ list ->
                    polyline
                        [ points points_
                        , css
                            [ Css.property "stroke-width" gridUnitString
                            , Css.property "stroke" record.color
                            , Css.property "fill" "none"
                            , Css.property "stroke-linejoin" "round"
                            ]
                        ]
                        []

                _ ->
                    text ""

        path x y =
            "/images/snake/" ++ x ++ "/" ++ y ++ ".svg#root"

        embed transform_ part type_ { pos, dir } =
            let
                center =
                    vec2 50 50

                dir_ =
                    dir |> toTuple
            in
            g
                [ transformList [ "scale(0.8)", translate (positionPos pos), iconRotation center dir_ ] ]
                [ g []
                    [ Svg.title [] [ text (toString dir_) ]
                    , (case part of
                        "head" ->
                            Game.SnakeImages.Heads.getSnakeHead type_

                        "tail" ->
                            Game.SnakeImages.Tails.getSnakeTail type_

                        _ ->
                            Debug.crash part
                      )
                        [ css [ Css.property "fill" record.color ]
                        , opacity opacityValue
                        ]
                        []
                    ]
                ]

        icons =
            case coords of
                AccInit ->
                    []

                AccFirst start ->
                    [ start |> embed "" "head" record.headType ]

                Acc start end _ _ _ ->
                    [ start |> embed "" "head" record.headType
                    , end |> embed "" "tail" record.tailType
                    ]
    in
    [ g
        [ vec2 (gridPathOffset - 30) (gridPathOffset - 30)
            |> translate
            |> transform
        , opacity opacityValue
        ]
        [ polyline_ ]
    ]
        ++ icons


positionPos : Vec2 -> Vec2
positionPos pos =
    vec2
        (pos
            |> getX
            |> scale
            |> (*) 1.25
        )
        (pos
            |> getY
            |> scale
            |> (*) 1.25
        )


rotate : a -> String
rotate value =
    "rotate(" ++ (value |> toString) ++ ")"


rotate2 : a -> Vec2 -> String
rotate2 value vec =
    "rotate("
        ++ toString value
        ++ " "
        ++ (vec |> getX |> toString)
        ++ ","
        ++ (vec |> getY |> toString)
        ++ ")"


translate : Vec2 -> String
translate vec =
    "translate("
        ++ (vec |> getX |> toString)
        ++ ","
        ++ (vec |> getY |> toString)
        ++ ")"


verticalFlip : String
verticalFlip =
    "scale(-1,1) translate(-1, 0)"


transformList : List String -> Attribute msg
transformList list =
    transform (String.join " " list)


transformOrigin : String -> Css.Style
transformOrigin value =
    Css.property "transform-origin" value


iconRotation : Vec2 -> ( number, number1 ) -> String
iconRotation center vec =
    case vec of
        ( 0, 0 ) ->
            rotate2 -90 center

        ( 1, 0 ) ->
            ""

        ( -1, 0 ) ->
            String.join " " [ "scale(-1, 1)", translate (vec2 -100 0) ]

        ( -1, 1 ) ->
            rotate2 45 center

        ( 0, 1 ) ->
            rotate2 90 center

        ( 0, -1 ) ->
            rotate2 -90 center

        ( _, _ ) ->
            Debug.crash (toString vec)
