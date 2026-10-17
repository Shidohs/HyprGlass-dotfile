-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃          Application Variables (env)  (12-app-vars.lua)     ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

-- Terminal & editor
hl.env("TERM",     "xterm-256color")
hl.env("TERMINAL", "kitty")
hl.env("EDITOR",   "nano")

-- Application shortcuts (used by other tools via env)
hl.env("APP_TERMINAL",    "kitty")
hl.env("APP_FILEMANAGER", "nemo")
hl.env("APP_MENU",        "fuzzel")
hl.env("APP_CODE",        "code")
hl.env("APP_BROWSER",     "zen")
