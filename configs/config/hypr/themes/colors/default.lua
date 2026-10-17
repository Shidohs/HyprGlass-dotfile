-- Default theme colors for Hyprland
-- Mirrors: themes/colors/default.conf

local M = {}

-- Window colors
M.active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }
M.inactive_border = "rgba(595959aa)"

-- Workspace colors
M.active_workspace   = "rgba(33ccffee)"
M.inactive_workspace = "rgba(595959aa)"
M.urgent_workspace   = "rgba(ff0000ee)"

-- Bar colors
M.bar_background = "rgba(1a1a1aee)"
M.bar_foreground = "rgba(ffffffee)"

-- Notification colors
M.notification_background = "rgba(1a1a1aee)"
M.notification_foreground = "rgba(ffffffee)"
M.notification_error      = "rgba(ff0000ee)"
M.notification_warning    = "rgba(ffff00ee)"

-- Menu colors
M.menu_background = "rgba(1a1a1aee)"
M.menu_foreground = "rgba(ffffffee)"
M.menu_selected   = "rgba(33ccffee)"

return M
