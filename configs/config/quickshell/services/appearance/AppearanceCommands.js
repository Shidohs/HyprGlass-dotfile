.pragma library

function shellEscape(str) {
    return "'" + String(str).replace(/'/g, "'\\''") + "'";
}

function listJsonThemeNamesCommand(themesDir) {
    return "ls -1 " + shellEscape(themesDir) + "/*.json 2>/dev/null | sed 's|.*/||;s|\\.json$||' | sort";
}

function loadThemePreviewsCommand(themesDir) {
    return "for f in " + shellEscape(themesDir) + "/*.json; do echo \"---THEME_NAME:$(basename \"$f\" .json)---\"; cat \"$f\"; echo '---THEME_SEP---'; done";
}

function applyHyprlandCommand(cmds) {
    return cmds.join(" && ");
}

function applyNeovimCommand(nvimThemePath, colorscheme) {
    return "printf '%s' " + shellEscape(colorscheme) + " > " + shellEscape(nvimThemePath) +
        " && for sock in /run/user/$(id -u)/nvim.*.0; do " +
        "  [ -S \"$sock\" ] && nvim --server \"$sock\" --remote-send '<Cmd>colorscheme " + colorscheme + "<CR>' 2>/dev/null & " +
        "done; wait";
}

function applyWallpaperCommand(path) {
    return "[ -f " + shellEscape(path) + " ] && awww img " + shellEscape(path) +
        " --transition-type grow --transition-duration 1 --transition-fps 60 --transition-step 90" +
        " || echo '[ThemeBackend] Wallpaper not found' >&2";
}

function writeGtkColorsCommand(gtkColorsPath3, gtkColorsPath4, content, gtkThemeName, scheme) {
    return "cat > " + shellEscape(gtkColorsPath3) + " << 'GTK_EOF'\n" + content + "\nGTK_EOF\n" +
        "cp " + shellEscape(gtkColorsPath3) + " " + shellEscape(gtkColorsPath4) + " && " +
        "gsettings set org.gnome.desktop.interface gtk-theme " + shellEscape(gtkThemeName) + " 2>/dev/null; " +
        "gsettings set org.gnome.desktop.interface color-scheme " + shellEscape(scheme) + " 2>/dev/null; true";
}

function clearFilesCommand(paths) {
    return "rm -f " + paths.map(shellEscape).join(" ");
}

function switchGtkThemeCommand(gtkThemeName, scheme) {
    return "gsettings set org.gnome.desktop.interface gtk-theme " + shellEscape(gtkThemeName) + " 2>/dev/null; " +
        "gsettings set org.gnome.desktop.interface color-scheme " + shellEscape(scheme) + " 2>/dev/null; true";
}

function writeQtColorsCommand(colorSchemesDir, qtColorSchemePath, content, qt5ctConfPath, qt6ctConfPath, kdeglobalsPath) {
    var cmd = "mkdir -p " + shellEscape(colorSchemesDir) + " && " +
        "cat > " + shellEscape(qtColorSchemePath) + " << 'QT_EOF'\n" + content + "\nQT_EOF";

    // Update qt5ct to point to Lyne.colors and enable custom palette
    if (qt5ctConfPath) {
        cmd += "\n[ -f " + shellEscape(qt5ctConfPath) + " ] && " +
            "sed -i " +
            "'s|^color_scheme_path=.*|color_scheme_path=" + qtColorSchemePath + "|;" +
            "s|^custom_palette=.*|custom_palette=true|' " +
            shellEscape(qt5ctConfPath) + " || true";
    }

    // Update qt6ct to point to Lyne.colors and enable custom palette
    if (qt6ctConfPath) {
        cmd += "\n[ -f " + shellEscape(qt6ctConfPath) + " ] && " +
            "sed -i " +
            "'s|^color_scheme_path=.*|color_scheme_path=" + qtColorSchemePath + "|;" +
            "s|^custom_palette=.*|custom_palette=true|' " +
            shellEscape(qt6ctConfPath) + " || true";
    }

    // Merge color sections into kdeglobals using the just-written Lyne.colors file
    if (kdeglobalsPath) {
        cmd += "\nif [ -f " + shellEscape(kdeglobalsPath) + " ]; then " +
            "awk 'BEGIN{s=0} /^\\[(ColorEffects|Colors):/{s=1;next} /^\\[WM\\]/{s=1;next} /^\\[/{s=0} !s{print}' " +
            shellEscape(kdeglobalsPath) + " > " + shellEscape(kdeglobalsPath + ".tmp") +
            " && awk '/^\\[General\\]/{s=1;next} /^\\[/{s=0} !s{print}' " +
            shellEscape(qtColorSchemePath) + " >> " + shellEscape(kdeglobalsPath + ".tmp") +
            " && mv " + shellEscape(kdeglobalsPath + ".tmp") + " " + shellEscape(kdeglobalsPath) +
            "; fi";
    }

    return cmd;
}

function listSystemThemesCommand() {
    return "for d in /usr/share/themes $HOME/.themes $HOME/.local/share/themes; do " +
        "  [ -d \"$d\" ] && for t in \"$d\"/*/; do " +
        "    [ -d \"${t}gtk-3.0\" ] || [ -d \"${t}gtk-4.0\" ] && basename \"$t\"; " +
        "  done; " +
        "done | sort -u; " +
        "echo '---SECTION---'; " +
        "for d in /usr/share/icons $HOME/.icons $HOME/.local/share/icons; do " +
        "  [ -d \"$d\" ] && for t in \"$d\"/*/; do " +
        "    [ -f \"${t}index.theme\" ] && basename \"$t\"; " +
        "  done; " +
        "done | sort -u; " +
        "echo '---SECTION---'; " +
        "for d in /usr/share/icons $HOME/.icons $HOME/.local/share/icons; do " +
        "  [ -d \"$d\" ] && for t in \"$d\"/*/; do " +
        "    [ -d \"${t}cursors\" ] && basename \"$t\"; " +
        "  done; " +
        "done | sort -u";
}

function currentSystemThemeCommand() {
    return "gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d \"'\" ; " +
        "echo '---SEP---'; " +
        "gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d \"'\" ; " +
        "echo '---SEP---'; " +
        "gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d \"'\"";
}

function applySystemThemeCommand(unifierPath, gtkTheme, iconTheme, cursorTheme) {
    const cmds = [];
    if (gtkTheme)
        cmds.push("sed -i 's/^GTK_THEME=\".*\"/GTK_THEME=\"" + gtkTheme + "\"/' " + shellEscape(unifierPath));
    if (iconTheme)
        cmds.push("sed -i 's/^ICON_THEME=\".*\"/ICON_THEME=\"" + iconTheme + "\"/' " + shellEscape(unifierPath));
    if (cursorTheme)
        cmds.push("sed -i 's/^CURSOR_THEME=\".*\"/CURSOR_THEME=\"" + cursorTheme + "\"/' " + shellEscape(unifierPath));
    cmds.push(shellEscape(unifierPath) + " apply");
    if (cursorTheme)
        cmds.push("(command -v hyprctl >/dev/null 2>&1 && hyprctl setcursor " + shellEscape(cursorTheme) + " 24) || true");
    return cmds.join(" && ");
}

function copyToThemeCommand(dest, sourcePath) {
    return "mkdir -p " + shellEscape(dest) + " && cp " + shellEscape(sourcePath) + " " + shellEscape(dest);
}

function setThemeWallpaperCommand(jsonPath, relativePath) {
    return "jq '.wallpaper = " + shellEscape(relativePath) + "' " + shellEscape(jsonPath) +
        " > " + shellEscape(jsonPath + ".tmp") + " && mv " + shellEscape(jsonPath + ".tmp") + " " + shellEscape(jsonPath);
}

function listThemeWallpapersCommand(themeWallpaperDir, themeName) {
    const dir = themeWallpaperDir + "/" + themeName;
    return "mkdir -p " + shellEscape(dir) + " && ls -1 " + shellEscape(dir) + "/*.{png,jpg,jpeg,webp,gif} 2>/dev/null | sort";
}

function findWallpapersCommand(wallpaperDirs) {
    return "find " + wallpaperDirs.map(shellEscape).join(" ") +
        " -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg'" +
        " -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort -u";
}
