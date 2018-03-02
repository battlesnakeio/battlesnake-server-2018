module Decoder exposing (..)

import Dict
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Math.Vector2 exposing (..)
import Types exposing (..)


(:=) : String -> Decoder a -> Decoder a
(:=) =
    field


(@=) : List String -> Decoder a -> Decoder a
(@=) =
    at


maybeWithDefault : a -> Decoder a -> Decoder a
maybeWithDefault value decoder =
    decoder |> maybe |> map (Maybe.withDefault value)


tickDecoder : Decoder GameState
tickDecoder =
    "content" := gameStateDecoder


parseErrorDecoder : String -> Decoder a
parseErrorDecoder val =
    fail ("don't know how to parse [" ++ val ++ "]")


statusDecoder : Decoder Status
statusDecoder =
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
                    parseErrorDecoder x
        )
        string


gameStateDecoder : Decoder GameState
gameStateDecoder =
    map2 GameState
        ("board" := boardDecoder)
        ("status" := statusDecoder)


boardDecoder : Decoder Board
boardDecoder =
    map8 Board
        ("turn" := int)
        ("snakes" := list snakeDecoder)
        ("deadSnakes" := list snakeDecoder)
        ("gameId" := int)
        ("food" := list vec2Decoder)
        ("width" := int)
        ("height" := int)
        ("division" := string)


vec2Decoder : Decoder Vec2
vec2Decoder =
    map2 vec2
        (index 0 float)
        (index 1 float)


pointDecoder : Decoder Point
pointDecoder =
    map2 Point
        (index 0 int)
        (index 1 int)


point2Decoder : Decoder Point
point2Decoder =
    map2 Point
        ("x" := int)
        ("y" := int)


deathDecoder : Decoder Death
deathDecoder =
    decode Death
        |> required "causes" (list string)


snakeDecoder : Decoder Snake
snakeDecoder =
    decode Snake
        |> optional "death" (nullable deathDecoder) Nothing
        |> required "color" string
        |> required "coords" (list vec2Decoder)
        |> required "health" int
        |> required "id" string
        |> optional "name" string ""
        |> required "taunt" (maybe string)
        |> (string
                |> maybe
                |> map (Maybe.withDefault "")
                |> required "headUrl"
           )
        |> required "headType" string
        |> required "tailType" string


permalinkDecoder : Decoder Permalink
permalinkDecoder =
    map3 Permalink
        ("id" := string)
        ("url" := string)
        (succeed Loading)


databaseDecoder :
    Decoder { a | id : comparable }
    -> Decoder (Dict.Dict comparable { a | id : comparable })
databaseDecoder decoder =
    list decoder
        |> map (List.map (\y -> ( y.id, y )))
        |> map Dict.fromList


lobbyDecoder : Decoder Lobby
lobbyDecoder =
    map Lobby
        ("data" := databaseDecoder permalinkDecoder)


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
                (maybeWithDefault "" <| "headUrl" := string)
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
                        parseErrorDecoder x
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
        ("player" := snakeDecoder)
        ("world" := value)
