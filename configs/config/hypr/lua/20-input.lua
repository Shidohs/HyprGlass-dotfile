-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃               Input Configuration  (20-input.lua)           ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

hl.config({
    input = {
        -- Keyboard
        kb_layout  = "latam",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        repeat_rate  = 25,
        repeat_delay = 600,

        -- Mouse
        follow_mouse              = 1,
        float_switch_override_focus = 0,
        sensitivity               = 0,         -- -1.0 - 1.0, 0 = sin modificación
        scroll_points             = 15,
        scroll_method             = "normal",
        accel_profile             = "flat",     -- Sin aceleración: movimiento 1:1 puro
        force_no_accel            = true,       -- Fuerza desactivar accel a nivel kernel
        off_window_axis_events    = 2,          -- Procesa eventos fuera de ventana

        touchpad = {
            natural_scroll        = true,
            scroll_factor         = 0.5,
            disable_while_typing  = false,
            tap_to_click          = true,
        },
    },

    gestures = {
        workspace_swipe_distance              = 300,
        workspace_swipe_invert                = true,
        workspace_swipe_min_speed_to_force    = 30,
        workspace_swipe_cancel_ratio          = 0.5,
        workspace_swipe_create_new            = false,
        workspace_swipe_direction_lock        = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_use_r                 = true,
    },
})

-- Per-device config
-- hl.device({ name = "epic-mouse-v1", sensitivity = 0.5 })
