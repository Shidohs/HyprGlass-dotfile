-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃      Matugen Auto-Generated Colors  (00-colors.lua)         ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- This file is overwritten by the matugen / theme-manager workflow.
-- Load colors from the active theme (default or Matugen-overridden).
--
-- Strategy: try to load the Matugen runtime colors; if not present
-- fall back to the static default theme.

local ok, matugen = pcall(require, "matugen-colors")
if not ok then
    local ok_default, def = pcall(require, "themes.colors.default")
    if ok_default then
        matugen = def
    else
        matugen = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        }
    end
end

-- Re-export so other modules can: local C = require("hypr.lua.00-colors")
return matugen
