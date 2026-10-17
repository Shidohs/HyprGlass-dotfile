-- Hyprland Idle Daemon Configuration  (hypridle.lua)
-- Requires hypridle ≥ compatible with Lua config

local CFG = os.getenv("HOME") .. "/.config/hypr"

hl.config({
    general = {
        lock_cmd            = "pidof hyprlock || " .. CFG .. "/scripts/system/lock.sh",
        before_sleep_cmd    = CFG .. "/scripts/system/lock.sh",
        after_sleep_cmd     = "hyprctl dispatch dpms on",
        ignore_dbus_inhibit = false,
    },
})

-- Listener 1: Bloquear pantalla después de 25 minutos de inactividad
hl.listener({
    timeout    = 1500,
    on_timeout = CFG .. "/scripts/system/lock.sh",
    on_resume  = "hyprctl dispatch dpms on",
})

-- Listener 2: Apagar pantalla después de 30 minutos de inactividad
hl.listener({
    timeout    = 1800,
    on_timeout = "hyprctl dispatch dpms off",
    on_resume  = "hyprctl dispatch dpms on",
})

-- Listener 3: Suspensión después de 2 horas de inactividad (desactivado)
-- hl.listener({
--     timeout    = 7200,
--     on_timeout = "systemctl suspend",
--     on_resume  = "hyprctl dispatch dpms on",
-- })
