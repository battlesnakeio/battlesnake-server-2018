module Theme exposing (..)

import Css exposing (..)
import Scale exposing (..)


assets : { logoExpert : String, logoIntermediate : String, logoBeginner : String, logoLight : String, logo2018 : String, background : String }
assets =
    { logoExpert = "/images/BS18 Icon Advanced.png"
    , logoIntermediate = "/images/BS18 Icon Intermediate.png"
    , logoBeginner = "/images/BS18 Icon Beginner.png"
    , logoLight = "/images/logo-light.png"
    , logo2018 = "/images/BS18 BG DarkPurple.png"
    , background = "/images/BS18 BG DarkPurple.png"
    }


palette =
    { blue = hex "#99e1d9"
    , grey = hex "#5d576b"
    , medgrey = hex "#919191"
    , lightgrey = hex "#e8e8e8"
    , pink = hex "#f7567c"
    , purple = hex "#5c2e8c"
    , yellow = hex "#fffae3"
    , white = hex "#fcfcfc"
    }


theme =
    { bgPrimary = palette.purple
    , bgSecondary = palette.white
    , buttonAccent = palette.lightgrey
    , sidebarPlayerHeight = ms 3
    , sidebarWidth = px 900
    , tile = palette.lightgrey
    , food = palette.pink
    }


sidebarTheme : Style
sidebarTheme =
    batch
        [ backgroundColor theme.bgPrimary
        , color theme.bgSecondary
        ]
