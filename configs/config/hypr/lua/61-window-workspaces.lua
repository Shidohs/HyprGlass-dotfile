-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃       Workspace Routing Rules  (61-window-workspaces.lua)   ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

hl.window_rule({
    match     = { class = "^(alacritty|Alacritty|gnome%-terminal%-server|Gnome%-terminal%-server|kitty|konsole|Konsole|org%.gnome%.Terminal|org%.kde%.konsole)$" },
    workspace = 1,
})

hl.window_rule({
    match     = { class = "^(antigravity|code|Code|code%-oss|Code%-oss|idea|jetbrains%-clion|Jetbrains%-clion|jetbrains%-idea|Jetbrains%-idea|org%.sublimetext%.Sublime_text|org%.visualstudio%.Code|sublime_text|Sublime_text)$" },
    workspace = 2,
})

hl.window_rule({
    match     = { class = "^(brave%-browser|Brave%-browser|chromium|Chromium|firefox|Firefox|google%-chrome|Google%-chrome|microsoft%-edge|Microsoft%-edge|org%.chromium%.Chromium|org%.mozilla%.firefox|zen)$" },
    workspace = 3,
})

hl.window_rule({
    match     = { class = "^(discord|Discord|franz|Franz|slack|Slack|telegram%-desktop|TelegramDesktop|org%.telegram%.desktop|webcord|Webcord|whatsapp%-nativefier%-d40211|whatsdesk)$" },
    workspace = 4,
})

hl.window_rule({
    match     = { class = "^(eog|gwenview|libreoffice|LibreOffice|libreoffice%-calc|LibreOffice%-calc|libreoffice%-impress|LibreOffice%-impress|libreoffice%-writer|LibreOffice%-writer|mpv|.*[oO]bsidian.*|md\\.obsidian\\.Obsidian|obsidian|Obsidian|okular|onlyoffice%-desktopeditors|OnlyOffice%-desktopeditors|org%.kde%.gwenview|org%.libreoffice%.LibreOffice|org%.libreoffice%.libreoffice%-calc|org%.libreoffice%.libreoffice%-impress|org%.libreoffice%.libreoffice%-writer|spotify|Spotify|vlc)$" },
    workspace = 5,
})

hl.window_rule({
    match     = { class = "^(blueman%-manager|dolphin|fdm|GParted|limo|lxappearance|nemo|nm%-connection%-editor|org%.gnome%.DiskUtility|org%.gnome%.nautilus|org%.gnome%.Nautilus|org%.kde%.dolphin|org%.pulseaudio%.pavucontrol|pavucontrol|qt5ct|qt6ct|thunar)$" },
    workspace = 6,
})

hl.window_rule({
    match            = { class = "^(fci_recomp)$" },
    workspace        = "6 silent",
    no_initial_focus = true,
    suppress_event   = "activate",
})

hl.window_rule({
    match     = { class = "^(Cemu|geforcenow.*|geforce-now.*|heroic|Heroic|io%.github%.hmlendea%.geforcenow%-electron|lutris|Lutris|minecraft|Minecraft|minecraft%-launcher|Minecraft Launcher|minetest|Minetest|Moonlight|moonlight|com.moonlight_stream.Moonlight|com%.moonlight_stream%.Moonlight|net%.lutris%.Lutris|pcsx2%-qt|SKlauncher.*|steam|Steam|steam_app_.*|Yuzu|.*%.exe.*|.*%.EXE.*|[wW]ine.*|[pP]roton.*)$" },
    workspace = 7,
})
