module Decoder exposing (..)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Types exposing (..)
import Dict
import Math.Vector2 exposing (..)


(:=) : String -> Decoder a -> Decoder a
(:=) =
    field


(@=) : List String -> Decoder a -> Decoder a
(@=) =
    at


defaultHeadUrl : String
defaultHeadUrl =
    ""

defaultHeadType : String
defaultHeadType = 
    ""

defaultTailType : String
defaultTailType = 
    ""

defaultDeath : Death
defaultDeath = 
    { causes = [] }

maybeWithDefault : a -> Decoder a -> Decoder a
maybeWithDefault value decoder =
    decoder |> maybe |> map (Maybe.withDefault value)


tick : Decoder GameState
tick =
    ("content" := gameState)


parseError : String -> Decoder a
parseError val =
    fail ("don't know how to parse [" ++ val ++ "]")


status : Decoder Status
status =
    andThen
        (\x ->
            case x of
                "cont" ->
                    succeed Cont

                "suspend" ->
                    succeed Suspended

                "halted" ->
                    succeed Halted

                _ ->
                    parseError x
        )
        string


gameState : Decoder GameState
gameState =
    map2 GameState
        ("board" := board)
        ("status" := status)


board : Decoder Board
board =
    map7 Board
        ("turn" := int)
        ("snakes" := list snake)
        ("deadSnakes" := list snake)
        ("gameId" := int)
        ("food" := list decodeVec2)
        ("width" := int)
        ("height" := int)

decodeVec2 : Decoder Vec2
decodeVec2 = 
    map2 vec2
        (index 0 float)
        (index 1 float)

point : Decoder Point
point =
    map2 Point
        (index 0 int)
        (index 1 int)


point2 : Decoder Point
point2 =
    map2 Point
        ("x" := int)
        ("y" := int)


death : Decoder Death
death =
    map Death
        ("causes" := list string)


snake : Decoder Snake
snake =
    decode Snake
        |> hardcoded Nothing
        |> required "color" string
        |> required "coords" (list decodeVec2)
        |> required "health" int
        |> required "id" string
        |> required "name" string
        |> required "taunt" (maybe string)
        |> (string
                |> maybe
                |> map (Maybe.withDefault "")
                |> required "headUrl"
           )
        |> required "headType" string
        |> required "tailType" string
    -- map10 Snake
    --     (maybe <| "death" := death)
    --     ("color" := string)
    --     ("coords" := list decodeVec2)
    --     ("health" := int)
    --     ("id" := string)
    --     ("name" := string)
    --     (maybe <| "taunt" := string)
    --     (maybeWithDefault defaultHeadUrl <| "headUrl" := string)
    --     (maybeWithDefault defaultHeadType <| "headType" := string)
    --     (maybeWithDefault defaultTailType <| "tailType" := string)


snake2 : Decoder Snake
snake2 =
    decode Snake
        |> hardcoded Nothing
        |> required "color" string
        |> required "coords" (list decodeVec2)
        |> required "health" int
        |> required "id" string
        |> required "name" string
        |> required "taunt" (maybe string)
        |> (string
                |> maybe
                |> map (Maybe.withDefault "")
                |> required "headUrl"
           )
        |> required "headType" string
        |> required "tailType" string
    -- map8 Snake
    --     (maybe <| "death" := death)
    --     ("color" := string)
    --     (at [ "body", "data" ] (list decodeVec2))
    --     ("health" := int)
    --     ("id" := string)
    --     ("name" := string)
    --     (maybe <| "taunt" := string)
    --     (maybeWithDefault defaultHeadUrl <| "headUrl" := string)


permalink : Decoder Permalink
permalink =
    map3 Permalink
        ("id" := string)
        ("url" := string)
        (succeed Loading)


database :
    Decoder { a | id : comparable }
    -> Decoder (Dict.Dict comparable { a | id : comparable })
database decoder =
    list decoder
        |> map (List.map (\y -> ( y.id, y )))
        |> map Dict.fromList


lobby : Decoder Lobby
lobby =
    map Lobby
        ("data" := database permalink)


gameEvent : Decoder a -> Decoder (GameEvent a)
gameEvent decoder =
    map2 GameEvent
        (at [ "rel", "game_id" ] int)
        decoder


snakeEvent : Decoder a -> Decoder (SnakeEvent a)
snakeEvent decoder =
    map3 SnakeEvent
        (at [ "rel", "game_id" ] int)
        (at [ "rel", "snake_id" ] string)
        decoder


error : Decoder (SnakeEvent String)
error =
    snakeEvent (at [ "data", "error" ] string)


lobbySnake : Decoder (SnakeEvent LobbySnake)
lobbySnake =
    let
        data =
            map6 LobbySnake
                ("color" := string)
                ("id" := string)
                ("name" := string)
                ("taunt" := maybe string)
                ("url" := string)
                (maybeWithDefault defaultHeadUrl <| "headUrl" := string)
    in
        snakeEvent (field "data" data)


v2 : Decoder V2
v2 =
    map2 V2
        ("x" := int)
        ("y" := int)


agent : Decoder Agent
agent =
    "body" := list v2


scenario : Decoder Scenario
scenario =
    map5 Scenario
        ("agents" := list agent)
        ("player" := agent)
        ("food" := list v2)
        ("width" := int)
        ("height" := int)


testCaseError : Decoder TestCaseError
testCaseError =
    ("object" := string)
        |> andThen
            (\object ->
                case object of
                    "assertion_error" ->
                        map Assertion assertionError

                    "error_with_reason" ->
                        map Reason errorWithReason

                    "error_with_multiple_reasons" ->
                        map MultipleReasons errorWithMultipleReasons

                    x ->
                        parseError x
            )


errorWithReason : Decoder ErrorWithReason
errorWithReason =
    map ErrorWithReason ("reason" := string)


errorWithMultipleReasons : Decoder ErrorWithMultipleReasons
errorWithMultipleReasons =
    map ErrorWithMultipleReasons ("errors" := list string)


assertionError : Decoder AssertionError
assertionError =
    map5 AssertionError
        ("id" := string)
        ("reason" := string)
        ("scenario" := scenario)
        ("player" := snake2)
        ("world" := value)
