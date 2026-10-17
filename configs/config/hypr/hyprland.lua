-- █▀▀ █▀█ █▀█ █▀▀ █▀ █▀▀ █▀█ █▀█ █▀ █▀▀ █▀
-- █▄▄ █▄█ █▀▄ ██▄ ▄█ █▄▄ █▀▄ █▄█ ▄█ ██▄ ▄█
-- HyprGlass – Main Hyprland Lua Configuration
-- Requires Hyprland ≥ 0.55

-- You can split this configuration into multiple files and require them here.
-- The Lua module path is set so that `require("hypr.lua.XX")` maps to
-- ~/.config/hypr/lua/XX.lua

-- ── Configurar package.path para resolución de módulos en ~/.config/hypr ────────
local hypr_dir = os.getenv("HOME") .. "/.config/hypr"
package.path = table.concat({
    hypr_dir .. "/?.lua",
    hypr_dir .. "/?/init.lua",
    hypr_dir .. "/lua/?.lua",
    hypr_dir .. "/lua/?/init.lua",
    package.path,
}, ";")

-- Invalidate cached modules so hyprctl reload re-executes all lua files
for k, _ in pairs(package.loaded) do
    if type(k) == "string" and (k:find("10%-defaults") or k:find("keybinds") or k:find("autostart") or k:find("lua/")) then
        package.loaded[k] = nil
    end
end

-- ── Load all modules from lua/ (sorted alphabetically) ───────────────────────
require("./lua/*")


-- ── Machine-specific overrides (git-ignored) ──────────────────────────────────
-- Create ~/.config/hypr/lua/99-local.lua for per-machine monitors, workspaces, etc.
--pcall(require, "hypr.lua.99-local")
