-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃            Decorations Configuration  (30-decorations.lua)  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

hl.config({
    decoration = {
        rounding = 12,

        blur = {
            enabled            = true,
            size               = 5,
            passes             = 2,
            new_optimizations  = true,
            ignore_opacity     = true,
            popups             = true,   -- Layer-shell popups
            popups_ignorealpha = 0.3,
            xray               = true,   -- Skip blur behind opaque windows
            vibrancy           = 0.16,
            vibrancy_darkness  = 0.5,
            special            = false,  -- Disabled on special workspace for FPS
        },

        shadow = {
            enabled = false,
        },

        inactive_opacity = 1.0,
        active_opacity   = 1.0,
        dim_inactive     = false,
        dim_strength     = 0.1,
    },
})
