-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃               Autostart Configuration  (80-autostart.lua)   ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

local ok_defaults, D = pcall(require, "10-defaults")
if not ok_defaults or type(D) ~= "table" then
    ok_defaults, D = pcall(require, "hypr.lua.10-defaults")
    if not ok_defaults or type(D) ~= "table" then
        local HOME = os.getenv("HOME")
        local CFG_FALLBACK  = HOME .. "/.config/hypr"
        local rofiUtils = HOME .. "/.config/rofi/bin"
        D = {
            idlehandler    = CFG_FALLBACK .. "/scripts/system/idle-config.sh",
            lockCmd        = CFG_FALLBACK .. "/scripts/system/lock.sh",
            sttCmd         = CFG_FALLBACK .. "/scripts/system/transcribirAudio/stt.sh",
            themeManager   = CFG_FALLBACK .. "/scripts/system/theme-manager.sh",
            wallpaperCtrl  = CFG_FALLBACK .. "/scripts/tools/wallpaper-control.sh",
            rofiUtils      = rofiUtils,
            launcher       = "launcher-ctl toggle",
            powermenu      = rofiUtils .. "/powermenu",
            terminal       = "kitty",
            fileManager    = "nemo",
            menu           = rofiUtils .. "/launcher",
            code           = "code",
            browser        = "zen",
        }
    end
end
local CFG = os.getenv("HOME") .. "/.config/hypr"

hl.on("hyprland.start", function()
    -- Wallpaper (with pywal color generation)
    hl.exec_cmd(D.wallpaperCtrl .. " change --pywal")

    -- Theme unification (cursor + Qt/GTK themes)
    hl.exec_cmd(CFG .. "/scripts/system/theme-unifier.sh apply")

    -- Authentication
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh")
    hl.exec_cmd(CFG .. "/scripts/system/polkit-agent.sh")

    -- DBus environment update
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")

    -- Disk automount
    hl.exec_cmd("udiskie")

    -- Geoclue agent
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")

    -- XSettings daemon (GTK theme support)
    hl.exec_cmd("xsettingsd")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Idle configuration
    hl.exec_cmd(CFG .. "/scripts/system/idle-config.sh")

    -- XDG Portal setup
    hl.exec_cmd(CFG .. "/scripts/system/xdgportal.sh")

    -- Quickshell bar (with environment import and delay)
    hl.exec_cmd("systemctl --user import-environment PATH WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORM && sleep 1 && " .. CFG .. "/scripts/start-quickshell.sh")

    -- Fast Rust Launcher Daemon
    hl.exec_cmd("launcher --daemon")

    -- Wallpaper daemon (awww or swww fallback)
    hl.exec_cmd("systemctl --user import-environment PATH WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORM && sleep 1 && (awww-daemon || swww-daemon)")
end)
