-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃               Variables Configuration (05-variables.lua)    ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- https://wiki.hypr.land/configuring/core/config-options/

local ok, C = pcall(require, "00-colors")
if not ok or type(C) ~= "table" then
    ok, C = pcall(require, "hypr.lua.00-colors")
    if not ok or type(C) ~= "table" then
        C = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        }
    end
end

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 4,
        border_size = 2,
        col = {
            active_border   = C.active_border,
            inactive_border = C.inactive_border,
        },
        layout        = "dwindle",
        allow_tearing = true,
        resize_on_border = true,
        extend_border_grab_area = 20,
        hover_icon_on_border = true,
        snap = {
            enabled = true,
        },
    },

    misc = {
        font_family         = "Cantarell",
        splash_font_family  = "Fira Sans",
        disable_hyprland_logo = true,
        focus_on_activate   = true,
        vrr                 = 2,
    },

    render = {
        direct_scanout = true,
    },

    dwindle = {
        special_scale_factor = 0.8,
        preserve_split       = true,
    },

    master = {
        new_status           = "master",
        special_scale_factor = 0.8,
    },
})
