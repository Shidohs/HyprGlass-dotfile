-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃               Keybinds Configuration  (70-keybinds.lua)     ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

local ok_defaults, D = pcall(require, "10-defaults")
if not ok_defaults or type(D) ~= "table" then
    ok_defaults, D = pcall(require, "hypr.lua.10-defaults")
    if not ok_defaults or type(D) ~= "table" then
        local HOME = os.getenv("HOME")
        local CFG  = HOME .. "/.config/hypr"
        local rofiUtils = HOME .. "/.config/rofi/bin"
        D = {
            idlehandler    = CFG .. "/scripts/system/idle-config.sh",
            lockCmd        = CFG .. "/scripts/system/lock.sh",
            sttCmd         = CFG .. "/scripts/system/transcribirAudio/stt.sh",
            themeManager   = CFG .. "/scripts/system/theme-manager.sh",
            wallpaperCtrl  = CFG .. "/scripts/tools/wallpaper-control.sh",
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

-- ── Modifier aliases ──────────────────────────────────────────────────────────
local SUPER  = "SUPER"
local ALT    = "ALT"
local CTRL   = "CTRL"
local SHIFT  = "SHIFT"

-- ── Lid switch ────────────────────────────────────────────────────────────────
hl.bind("switch:on:Lid Switch", function() hl.exec_cmd(D.lockCmd .. " ; systemctl suspend") end, { locked = true })

-- ── App launchers ─────────────────────────────────────────────────────────────
hl.bind(SUPER .. " + Return", hl.dsp.exec_cmd(D.terminal))
hl.bind(SUPER .. " + E",      hl.dsp.exec_cmd(D.fileManager))
hl.bind(SUPER .. " + R",      hl.dsp.exec_cmd(D.menu))
hl.bind(SUPER .. " + " .. SHIFT .. " + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(SUPER .. " + C",      hl.dsp.exec_cmd(D.code))
hl.bind(SUPER .. " + B",      hl.dsp.exec_cmd(D.browser))

-- ── Rofi menus ────────────────────────────────────────────────────────────────
hl.bind(SUPER .. " + D",                   hl.dsp.exec_cmd(D.launcher))
hl.bind(SUPER .. " + " .. SHIFT .. " + D", hl.dsp.exec_cmd(D.powermenu))
hl.bind(SUPER .. " + " .. ALT .. " + D",   hl.dsp.global("quickshell:app_launcher"))

-- ── Quickshell global shortcuts ───────────────────────────────────────────────
hl.bind(SUPER .. " + " .. SHIFT .. " + V", hl.dsp.global("quickshell:clipboard_history"))
hl.bind(SUPER .. " + F1",                  hl.dsp.global("quickshell:keybinds_help"))
hl.bind("Print",                            hl.dsp.global("quickshell:take_screenshot"))
hl.bind(SUPER .. " + W",                   hl.dsp.global("quickshell:wallpaper_picker"))
hl.bind(SUPER .. " + O",                   hl.dsp.global("quickshell:orbit_assistant"))
hl.bind(SUPER .. " + A",                   hl.dsp.global("quickshell:orbit_assistant"))

-- ── Window management ─────────────────────────────────────────────────────────
hl.bind(SUPER .. " + Q",                   hl.dsp.window.close())
hl.bind(SUPER .. " + M",                   hl.dsp.exec_cmd(D.lockCmd:gsub("lock.sh", "exit-confirm.sh")))
hl.bind(SUPER .. " + V",                   hl.dsp.window.float({ action = "toggle" }))
hl.bind(SUPER .. " + P",                   hl.dsp.window.pseudo())
hl.bind(SUPER .. " + J",                   hl.dsp.layout("togglesplit"))
hl.bind(SUPER .. " + " .. ALT .. " + Tab", hl.dsp.window.cycle_next())
hl.bind(SUPER .. " + Tab",                 hl.dsp.focus({ workspace = "previous" }))

-- Focus with arrow keys
hl.bind(SUPER .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(SUPER .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(SUPER .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(SUPER .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(SUPER .. " + F",     hl.dsp.window.fullscreen())

-- ── Workspace switching ───────────────────────────────────────────────────────
for i = 1, 7 do
    hl.bind(SUPER .. " + " .. i,                   hl.dsp.focus({ workspace = i }))
    hl.bind(SUPER .. " + " .. SHIFT .. " + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- ── Special workspace (scratchpad) ────────────────────────────────────────────
hl.bind(SUPER .. " + S",                   hl.dsp.workspace.toggle_special("magic"))
hl.bind(SUPER .. " + " .. SHIFT .. " + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- ── Mouse workspace scroll ────────────────────────────────────────────────────
hl.bind(SUPER .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(SUPER .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ── Move/resize with mouse ────────────────────────────────────────────────────
hl.bind(SUPER .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(SUPER .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── System ────────────────────────────────────────────────────────────────────
hl.bind(SUPER .. " + L",              hl.dsp.exec_cmd(D.lockCmd))
hl.bind(SUPER .. " + " .. ALT .. " + V", hl.dsp.exec_cmd(D.sttCmd))
hl.bind(SUPER .. " + " .. ALT .. " + C", hl.dsp.exec_cmd("wl-paste | xargs -I {} " .. D.code .. " {}"))

-- ── Volume and brightness (mapped to Quickshell) ──────────────────────────────
hl.bind("XF86AudioRaiseVolume",   hl.dsp.global("quickshell:volume_up"),   { repeating = true })
hl.bind("XF86AudioLowerVolume",   hl.dsp.global("quickshell:volume_down"), { repeating = true })
hl.bind("XF86AudioMute",          hl.dsp.global("quickshell:volume_mute"), { repeating = true })
hl.bind("XF86MonBrightnessUp",    hl.dsp.global("quickshell:brightness_up"),   { repeating = true })
hl.bind("XF86MonBrightnessDown",  hl.dsp.global("quickshell:brightness_down"), { repeating = true })

-- ── Wallpaper controls ────────────────────────────────────────────────────────
hl.bind(SUPER .. " + " .. SHIFT .. " + W", hl.dsp.exec_cmd(D.wallpaperCtrl .. " change"))
hl.bind(SUPER .. " + " .. ALT .. " + W",   hl.dsp.exec_cmd(D.wallpaperCtrl .. " status"))

-- ── Theme controls ────────────────────────────────────────────────────────────
hl.bind(SUPER .. " + " .. SHIFT .. " + T", hl.dsp.exec_cmd(D.themeManager .. " select"))
hl.bind(SUPER .. " + " .. CTRL .. " + T",  hl.dsp.exec_cmd(D.themeManager .. " apply"))
hl.bind(SUPER .. " + " .. SHIFT .. " + C", hl.dsp.exec_cmd(D.themeManager .. " cursor"))
