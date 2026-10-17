-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃           Layer Rules  (62-layer-rules.lua)                 ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

-- Rofi (Launcher & Dialogs)
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.3, animation = "fade" })

-- SwayNC Notification Window
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.3, animation = "slide right" })

-- Quickshell panels
hl.layer_rule({ match = { namespace = "qs_.*" }, blur = true, ignore_alpha = 0.3 })
-- The full-screen click-catcher is transparent; keep it out of the blur pass.
hl.layer_rule({ match = { namespace = "qs_fullscreen" }, blur = false })

-- SwayNC Control Center
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0.3, animation = "popin" })
