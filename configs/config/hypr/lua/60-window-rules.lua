-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃         Shared Window Rules  (60-window-rules.lua)          ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

-- ── Special windows ───────────────────────────────────────────────────────────

hl.window_rule({
    match   = { class = "org%.antigravity%.glass_launcher|glass%-launcher" },
    float   = true,
    fullscreen = true,
})

hl.window_rule({
    match   = { class = "Eww", title = "eww.*" },
    float   = true,
    no_focus = true,
    opacity = 0.8,
})

hl.window_rule({
    match = { class = "scrcpy" },
    float = true,
})

hl.window_rule({
    match    = { class = "xwaylandvideobridge" },
    max_size = { 1, 1 },
    no_anim  = true,
    no_blur  = true,
    no_focus = true,
    no_initial_focus = true,
    opacity  = 0.0,
})

-- ── Dialogs and portals ───────────────────────────────────────────────────────

hl.window_rule({
    match    = { class = "dolphin|file%-roller|nemo|Nemo|org%.gnome%.Nautilus|org%.kde%.dolphin|thunar" },
    float    = true,
    maximize = false,
    center   = true,
    size     = { "monitor_w*0.65", "monitor_h*0.75" },
})

hl.window_rule({
    match  = { title = "^(Save As|Open|Open File|Open Folder|Save File|File Upload|File Download|Choose File|Select a File|Select Files|Select Folder|Select Project Root).*" },
    float  = true,
    center = true,
    size   = {"monitor_w*0.7", "monitor_h*0.8" },
})

hl.window_rule({
    match  = { title = "^(Guardar como|Abrir|Abrir archivo|Abrir carpeta|Guardar archivo|Subir archivo|Descargar archivo|Elegir archivo|Seleccionar un archivo|Seleccionar archivos|Seleccionar carpeta|Elegir archivos|Añadir un juego nuevo|Extraer|Carga de archivos|Añadir juegos a Lutris|Escoger archivo ROM|Renombrar|Escoger carpeta|Escoger archivo|Agregar carpeta al área de trabajo).*" },
    float  = true,
    center = true,
    size   = {"monitor_w*0.7", "monitor_h*0.8" },
})

hl.window_rule({
    match = { title = "^(Settings|Preferences|Options).*" },
    float = true,
    size  = {"monitor_w*0.6", "monitor_h*0.7" },
})

hl.window_rule({
    match = { title = "^(Configuración|Preferencias|Opciones).*" },
    float = true,
    size  = {"monitor_w*0.6", "monitor_h*0.7" },
})

hl.window_rule({
    match = { class = "kdialog|org%.kde%.kdialog" },
    float = true,
    size  = {"monitor_w*0.6", "monitor_h*0.7" },
})

hl.window_rule({
    match  = { class = "^([xX]dg%-desktop%-portal.*|[xX]dg%-desktop%-portal%-gtk|[xX]dg%-desktop%-portal%-kde)$" },
    float  = true,
    center = true,
    size   = {"monitor_w*0.7", "monitor_h*0.8" },
})

hl.window_rule({
    match = { class = "Progreso de las operaciones de archivo" },
    float = true,
    size  = {"monitor_w*0.5", "monitor_h*0.3" },
})

-- ── System utilities ──────────────────────────────────────────────────────────

hl.window_rule({
    match = { class = "^(polkit%-gnome%-authentication%-agent%-1|hyprpolkitagent|org%.kde%.polkit%-kde%-authentication%-agent%-1|org%.org%.kde%.polkit%-kde%-authentication%-agent%-1).*$" },
    float = true,
    size  = {"monitor_w*0.6", "monitor_h*0.7" },
})

hl.window_rule({
    match = { class = "^(pavucontrol|org%.pulseaudio%.pavucontrol)$" },
    float = true,
    size  = {"monitor_w*0.5", "monitor_h*0.6" },
})

hl.window_rule({
    match = { class = "^(blueman%-manager|org%.blueman%.blueman%-manager)$" },
    float = true,
    size  = {"monitor_w*0.5", "monitor_h*0.6" },
})

hl.window_rule({
    match = { class = "^(nm%-connection%-editor|org%.gnome%.NetworkManager%.Editor|org%.kde%.nm%-connection%-editor)$" },
    float = true,
    size  = {"monitor_w*0.5", "monitor_h*0.6" },
})

hl.window_rule({
    match = { class = "^(lxappearance|org%.gnome%.Appearance|nwg%-look|qt5ct|qt6ct)$" },
    float = true,
    size  = {"monitor_w*0.5", "monitor_h*0.6" },
})

hl.window_rule({
    match            = { class = "dunst|mako|notification%-daemon|swaync|swaync%-control%-center|swaync%-notification%-window" },
    no_focus         = true,
    no_initial_focus = true,
    opacity          = 0.9,
})

hl.window_rule({
    match    = { class = "^(pamac%-manager|org%.gnome%.Software|org%.kde%.discover|discover|synaptic)$" },
    float    = true,
    maximize = false,
})

hl.window_rule({
    match = { class = "GParted|org%.gnome%.DiskUtility" },
    float = true,
})

hl.window_rule({
    match    = { class = "^(eog|org%.gnome%.eog|gwenview|org%.kde%.gwenview|feh|sxiv)$" },
    float    = true,
    maximize = false,
})

-- ── Application behavior ──────────────────────────────────────────────────────

hl.window_rule({
    match    = { class = "^(brave%-browser|Brave%-browser|chromium|Chromium|firefox|Firefox|google%-chrome|Google%-chrome|microsoft%-edge|Microsoft%-edge|org%.chromium%.Chromium|org%.mozilla%.firefox|zen)$" },
    float    = false,
    maximize = false,
    size     = {"monitor_w*0.8", "monitor_h*0.9" },
})

hl.window_rule({
    match    = { class = "^(TelegramDesktop|telegram%-desktop|org%.telegram%.desktop)$" },
    float    = true,
    maximize = false,
    size     = {"monitor_w*0.8", "monitor_h*0.9" },
})

hl.window_rule({
    match    = { class = "^(discord|Discord|franz|Franz|slack|Slack|webcord|Webcord|whatsapp%-nativefier%-d40211|whatsdesk)$" },
    float    = true,
    maximize = false,
    size     = {"monitor_w*0.8", "monitor_h*0.9" },
})

hl.window_rule({
    match    = { class = "^(libreoffice|LibreOffice|libreoffice%-calc|LibreOffice%-calc|libreoffice%-impress|LibreOffice%-impress|libreoffice%-writer|LibreOffice%-writer|onlyoffice%-desktopeditors|OnlyOffice%-desktopeditors|org%.libreoffice%.LibreOffice|org%.libreoffice%.libreoffice%-calc|org%.libreoffice%.libreoffice%-impress|org%.libreoffice%.libreoffice%-writer)$" },
    float    = true,
    maximize = false,
    size     = {"monitor_w*0.8", "monitor_h*0.9" },
})

hl.window_rule({
    match    = { class = "^(alacritty|Alacritty|gnome%-terminal%-server|Gnome%-terminal%-server|kitty|konsole|Konsole|org%.gnome%.Terminal|org%.kde%.konsole)$" },
    float    = true,
    maximize = false,
    size     = {"monitor_w*0.8", "monitor_h*0.9" },
})

hl.window_rule({
    match   = { class = "^(Cemu|heroic|Heroic|lutris|Lutris|minecraft|Minecraft|minecraft%-launcher|Minecraft Launcher|minetest|Minetest|net%.lutris%.Lutris|pcsx2%-qt|steam|Steam|Yuzu)$" },
    no_anim = true,
})

hl.window_rule({
    match     = { class = "^(steam_app_.*|gamescope|lutris|heroic|pcsx2.*|duckstation.*|retroarch|Moonlight|moonlight|com%.moonlight_stream%.Moonlight)$" },
    immediate = true,
})

hl.window_rule({
    match            = { class = "^(traductor%-overlay|game%-translate%-overlay)$" },
    float            = true,
    no_blur          = true,
    no_shadow        = true,
    pin              = true,
    no_focus         = true,
    no_initial_focus = true,
    opacity          = 1.0,
    move             = {0, 0 },
    size             = {"100%", "100%" },
    animation        = "none",
})

hl.window_rule({
    match = { class = "^(waydroid|Waydroid)$" },
    float = true,
})

hl.window_rule({
    match   = { class = "^(code|Code|code%-oss|Code%-oss|org%.visualstudio%.Code)$" },
    opacity = 0.98,
})

-- ── Global rules ──────────────────────────────────────────────────────────────

hl.window_rule({
    match          = { class = ".*" },
    suppress_event = "maximize",
})
