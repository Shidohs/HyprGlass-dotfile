-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃              Defaults Configuration  (10-defaults.lua)      ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- Central place for script/app path variables.
-- Export this module so keybinds and autostart can import it.

local HOME = os.getenv("HOME")
local CFG  = HOME .. "/.config/hypr"

local M = {}

-- Scripts
M.idlehandler    = CFG .. "/scripts/system/idle-config.sh"
M.lockCmd        = CFG .. "/scripts/system/lock.sh"
M.sttCmd         = CFG .. "/scripts/system/transcribirAudio/stt.sh"
M.themeManager   = CFG .. "/scripts/system/theme-manager.sh"
M.wallpaperCtrl  = CFG .. "/scripts/tools/wallpaper-control.sh"

-- Rofi utils / Fast Rust Launcher
M.rofiUtils      = HOME .. "/.config/rofi/bin"
M.launcher       = "launcher-ctl toggle"
M.powermenu      = M.rofiUtils .. "/powermenu"

-- Apps
M.terminal    = "kitty"
M.fileManager = "nemo"
M.menu        = M.rofiUtils .. "/launcher"
M.code        = "code"
M.browser     = "zen"

return M
