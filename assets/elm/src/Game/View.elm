module Game.View exposing (..)

import Css exposing (..)
import Game.BoardView
import Game.Types exposing (..)
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (..)
import Html.Styled.Events exposing (..)
import Md exposing (..)
import Route exposing (..)
import Scale exposing (..)
import Theme exposing (..)
import Types exposing (..)


replace : String -> String -> String -> String
replace search replace str =
    String.split search str
        |> String.join replace


view : Model -> Html Msg
view model =
    div
        [ css
            [ color palette.white
            , Css.backgroundImage (url (replace " " "%20" assets.background))
            , Css.backgroundSize (pct 100)
            ]
        ]
        [ viewPort []
            [ div
                [ css
                    [ displayFlex
                    , flexDirection Css.column
                    , alignItems center
                    , flexGrow (Css.int 3)
                    ]
                ]
                [ model.gameState
                    |> Maybe.map .board
                    |> Maybe.map Game.BoardView.view
                    |> Maybe.withDefault (text "")
                , div
                    [ css
                        [ displayFlex
                        , flexGrow (int 0)
                        , flexDirection Css.row
                        , justifyContent spaceBetween
                        , Css.width (Css.pct 90)
                        ]
                    ]
                    [ avControls []
                        [ btn
                            [ onClick (Push PrevStep)
                            , title "Previous turn (k)"
                            ]
                            [ mdSkipPrev ]
                        , btn
                            [ onClick (Push StopGame)
                            , title "Reset Game (q)"
                            ]
                            [ mdReplay ]
                        , playPause model
                        , btn
                            [ onClick (Push NextStep)
                            , title "Next turn (j)"
                            ]
                            [ mdSkipNext ]
                        ]
                    , div [ css [ alignSelf center ] ]
                        [ text ("Turn " ++ turn model)
                        , textSpacer
                        , a [ href <| editGamePath model.gameid ] [ text "Edit" ]
                        , textSpacer
                        , a [ href <| gamesPath ] [ text "Games" ]
                        ]
                    ]
                ]
            , sidebar model
            ]
        ]


textSpacer : Html msg
textSpacer =
    span [ css [ paddingLeft (px 10), paddingRight (px 10) ] ]
        [ text "|" ]


board : Model -> Html msg
board { gameid } =
    container
        [ css
            [ position relative
            , margin ms0
            ]
        ]
        [ div [ id gameid ] []
        ]


sidebar : Model -> Html Msg
sidebar model =
    let
        sidebarLogo =
            div
                [ css
                    [ displayFlex
                    , justifyContent spaceBetween
                    , marginBottom ms0
                    ]
            ]
            [ div
                [ ]
                [ img
                    [ src assets.logoLight
                    , css
                        [ Css.maxWidth (px 300)
                        , Css.display Css.block
                        , Css.marginTop Css.zero
                        , Css.marginBottom Css.zero
                        ]
                    ]
                    []
                ]
            , div
                [ css
                    [ displayFlex
                    , alignItems center
                    ]
                ]
                [ img
                    [ src assets.logoBeginner
                    , css
                        [ Css.maxHeight (px 100)
                        , marginRight ms2
                        ]
                    ]
                    []
                , img
                    [ src assets.logoIntermediate
                    , css
                        [ Css.maxHeight (px 100)
                        , marginRight ms2
                        ]
                    ]
                    []
                , img
                    [ src assets.logoExpert
                    , css
                        [ Css.maxHeight (px 100) ]
                ]
                []
                ]
            ]


        content =
            case model.gameState of
                Nothing ->
                    text "loading..."

                Just { board } ->
                    container []
                        (List.concat
                            [ List.map (snake True) board.snakes
                            , List.map (snake False) board.deadSnakes
                            ]
                        )
    in
    column
        [ css
            [ padding ms1
            , Css.width (pct 45)
            , justifyContent spaceBetween
            ]
        ]
        [ sidebarLogo
        , content
        ]


snake : Bool -> Snake -> Html msg
snake alive snake =
    let
        -- _ = Debug.log "snake" snake
        healthbarWidth =
            if alive then
                toString snake.health ++ "%"
            else
                "0%"

        transition =
            Css.batch <|
                if alive then
                    []
                else
                    [ Css.property "transition-property" "width, background-color"
                    , Css.property "transition-duration" "1s"
                    , Css.property "transition-timing-function" "ease"
                    ]

        healthbarStyle =
            [ ( "background-color", snake.color )
            , ( "width", healthbarWidth )
            ]

        healthbar =
            div
                [ style healthbarStyle
                , css
                    [ Css.height (px 10)
                    , transition
                    ]
                ]
                []

        healthText =
            if alive then
                toString snake.health
            else
                "Dead"

        containerOpacity =
            if alive then
                1
            else
                0.5

        taunt =
            case snake.taunt of
                Nothing ->
                    ""

                Just val ->
                    val
    in
    div
        [ css
            [ marginBottom ms_1
            , opacity (num containerOpacity)
            , position relative
            ]
        ]
        [ flag (avatar [ src snake.headUrl ] [])
            [ div
                [ css
                    [ displayFlex
                    , justifyContent spaceBetween
                    ]
                ]
                [ span [
                    css
                        [ paddingBottom ms_2
                        , paddingLeft ms0
                        , fontSize ms2
                        , fontWeight (int 800)
                        , lineHeight (int 1)
                        ]
                    ]
                    [ text snake.name ]
                , span
                    [ css
                        [ color palette.medgrey ]
                    ]
                    [ text healthText ]
                ]
            , div
                [ css
                    [ maxWidth theme.sidebarWidth
                    , paddingLeft ms0
                    , paddingBottom ms_1
                    , color palette.medgrey
                    , whiteSpace Css.noWrap
                    , textOverflow ellipsis
                    , overflow Css.hidden
                    ]
                ]
                [ text taunt ]
            , healthbar
            ]
        ]


playPause : Model -> Html Msg
playPause { gameState } =
    let
        gameEnded =
            btn [ title "Game ended", Attr.disabled True ] [ mdStop ]
    in
    case gameState of
        Nothing ->
            gameEnded

        Just { status } ->
            case status of
                Halted ->
                    gameEnded

                Suspended ->
                    btn
                        [ onClick (Push ResumeGame)
                        , title "Resume game (h)"
                        ]
                        [ mdPlayArrow ]

                Cont ->
                    btn
                        [ onClick (Push PauseGame)
                        , title "Pause game (l)"
                        ]
                        [ mdPause ]


column : List (Attribute msg) -> List (Html msg) -> Html msg
column =
    styled div
        [ displayFlex
        , flexDirection Css.column
        ]


row : List (Attribute msg) -> List (Html msg) -> Html msg
row =
    styled div
        [ displayFlex
        , flexDirection Css.row
        ]


viewPort : List (Attribute msg) -> List (Html msg) -> Html msg
viewPort =
    styled row [ Css.height (vh 100) ]


avControls : List (Attribute msg) -> List (Html msg) -> Html msg
avControls =
    styled div [ alignSelf center, flex Css.content, margin ms0 ]


sidebarControls : List (Attribute msg) -> List (Html msg) -> Html msg
sidebarControls =
    styled div
        [ displayFlex
        , justifyContent spaceAround
        ]


avatar : List (Attribute msg) -> List (Html msg) -> Html msg
avatar =
    styled img
        [ Css.width (px 96)
        , Css.height (px 96)
        ]


container : List (Attribute msg) -> List (Html msg) -> Html msg
container =
    styled div [ flex auto ]


btn : List (Attribute msg) -> List (Html msg) -> Html msg
btn =
    styled button
        [ border inherit
        , outline inherit
        , Css.property "-webkit-appearance" "none"
        , Css.property "-moz-appearance" "none"
        , backgroundColor inherit
        , color inherit
        , cursor pointer
        , Css.disabled
            [ backgroundColor inherit
            , color theme.buttonAccent
            ]
        , hover
            [ backgroundColor theme.buttonAccent
            , color theme.bgPrimary ]
        ]


flag : Html msg -> List (Html msg) -> Html msg
flag img_ body =
    div
        [ css
            [ displayFlex
            , minHeight theme.sidebarPlayerHeight
            ]
        ]
        [ img_
        , container [] body
        ]


turn : Model -> String
turn { gameState } =
    case gameState of
        Just { board } ->
            toString board.turn

        Nothing ->
            ""
