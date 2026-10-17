use serde_json::Value;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct ThemePalette {
    pub name: String,
    pub background: String,
    pub surface0: String,
    pub surface1: String,
    pub surface2: String,
    pub surface3: String,
    pub text: String,
    pub accent: String,
    pub muted: String,
    pub opacity: f32,
}

impl Default for ThemePalette {
    fn default() -> Self {
        Self {
            name: "Tokyo Night (Fallback)".to_string(),
            background: "#1a1b26".to_string(),
            surface0: "#24283b".to_string(),
            surface1: "#292e42".to_string(),
            surface2: "#414868".to_string(),
            surface3: "#565f89".to_string(),
            text: "#c0caf5".to_string(),
            accent: "#7aa2f7".to_string(),
            muted: "#565f89".to_string(),
            opacity: 0.82,
        }
    }
}

pub struct ThemeManager {
    state_file: PathBuf,
    matugen_palette_file: PathBuf,
    theme_dirs: Vec<PathBuf>,
    last_state_mtime: u64,
    last_palette_mtime: u64,
    current_palette: ThemePalette,
}

impl ThemeManager {
    pub fn new() -> Self {
        let home = dirs::home_dir().unwrap_or_else(|| PathBuf::from("/home/shidox"));

        let state_file = home
            .join(".config")
            .join("quickshell")
            .join("data")
            .join("state")
            .join("state.json");

        let matugen_palette_file = home
            .join(".cache")
            .join("matugen")
            .join("quickshell-palette.json");

        let theme_dirs = vec![
            home.join(".local").join("themes"),
            home.join("Público").join("lyne-dots").join(".data").join("themes"),
            home.join(".lyne-dots").join(".data").join("themes"),
        ];

        let mut manager = Self {
            state_file,
            matugen_palette_file,
            theme_dirs,
            last_state_mtime: 0,
            last_palette_mtime: 0,
            current_palette: ThemePalette::default(),
        };

        manager.reload();
        manager
    }

    #[allow(dead_code)]
    pub fn current_palette(&self) -> &ThemePalette {
        &self.current_palette
    }

    fn get_mtime(path: &Path) -> u64 {
        fs::metadata(path)
            .and_then(|m| m.modified())
            .ok()
            .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
            .map(|d| d.as_secs())
            .unwrap_or(0)
    }

    pub fn check_needs_reload(&self) -> bool {
        let state_m = Self::get_mtime(&self.state_file);
        let palette_m = Self::get_mtime(&self.matugen_palette_file);
        state_m > self.last_state_mtime || palette_m > self.last_palette_mtime
    }

    pub fn reload(&mut self) -> bool {
        self.last_state_mtime = Self::get_mtime(&self.state_file);
        self.last_palette_mtime = Self::get_mtime(&self.matugen_palette_file);

        let mut mode = "auto".to_string();
        let mut theme_name = "rose-pine".to_string();
        let mut opacity = 0.82f32;

        // 1. Read quickshell state.json
        if let Ok(content) = fs::read_to_string(&self.state_file) {
            if let Ok(json) = serde_json::from_str::<Value>(&content) {
                if let Some(m) = json.get("theme").and_then(|t| t.get("mode")).and_then(|v| v.as_str()) {
                    mode = m.to_string();
                }
                if let Some(n) = json.get("theme").and_then(|t| t.get("name")).and_then(|v| v.as_str()) {
                    theme_name = n.to_string();
                }
                if let Some(o) = json.get("opacity").and_then(|op| op.get("background")).and_then(|v| v.as_f64()) {
                    opacity = (o as f32).clamp(0.40, 1.0);
                }
            }
        }

        // 2. If Material You mode ("auto"), load from Matugen palette
        if mode == "auto" && self.matugen_palette_file.exists() {
            if let Some(palette) = self.load_matugen_palette(opacity) {
                self.current_palette = palette;
                return true;
            }
        }

        // 3. Otherwise preset theme mode: find <theme_name>.json
        if let Some(palette) = self.load_preset_theme(&theme_name, opacity) {
            self.current_palette = palette;
            return true;
        }

        // 4. Fallback to Matugen palette if preset wasn't found
        if let Some(palette) = self.load_matugen_palette(opacity) {
            self.current_palette = palette;
            return true;
        }

        false
    }

    fn load_matugen_palette(&self, opacity: f32) -> Option<ThemePalette> {
        let content = fs::read_to_string(&self.matugen_palette_file).ok()?;
        let json: Value = serde_json::from_str(&content).ok()?;
        Some(parse_palette_object(&json, "Material You (Matugen)", opacity))
    }

    fn load_preset_theme(&self, theme_name: &str, opacity: f32) -> Option<ThemePalette> {
        let trimmed = theme_name.trim();
        let lower = trimmed.to_lowercase();
        let hyphenated = lower.replace(' ', "-");
        let compact = lower.replace(['-', ' ', '_'], "");

        let variants = vec![
            format!("{}.json", trimmed),
            format!("{}.json", lower),
            format!("{}.json", hyphenated),
            format!("{}.json", compact),
        ];

        for dir in &self.theme_dirs {
            for target_file in &variants {
                let path = dir.join(target_file);
                if path.is_file() {
                    if let Ok(content) = fs::read_to_string(&path) {
                        if let Ok(json) = serde_json::from_str::<Value>(&content) {
                            let name = json
                                .get("name")
                                .and_then(|v| v.as_str())
                                .unwrap_or(theme_name)
                                .to_string();

                            let pal_obj = json.get("palette").unwrap_or(&json);
                            return Some(parse_palette_object(pal_obj, &name, opacity));
                        }
                    }
                }
            }
        }
        None
    }

    pub fn generate_css(&self) -> String {
        let p = &self.current_palette;
        let glass_opacity = (p.opacity * 0.60).clamp(0.40, 0.60);
        let bg_glass = hex_to_rgba(&p.background, glass_opacity);
        let accent_border = hex_to_rgba(&p.accent, 0.40);
        let selected_bg = hex_to_rgba(&p.accent, 0.45);
        let hover_bg = hex_to_rgba(&p.text, 0.08);

        format!(
            r#"
/* ==========================================================
 * Glass Launcher Theme: {name} (Integrated with Quickshell / Matugen)
 * ========================================================== */

window, window.launcher-window {{
    background-color: {bg_glass};
}}

.main-wrapper {{
    background-color: transparent;
    padding: 56px 32px 16px 32px;
}}

.search-container {{
    background-color: rgba(255, 255, 255, 0.07);
    border: 1px solid {accent_border};
    border-radius: 12px;
    padding: 10px 20px;
    margin-bottom: 20px;
}}

.search-icon {{
    color: {accent};
    font-family: "Iosevka Nerd Font", "Symbols Nerd Font Mono", monospace;
    font-size: 14pt;
    margin-right: 10px;
}}

.search-entry {{
    background: transparent;
    background-color: transparent;
    border: none;
    outline: none;
    box-shadow: none;
    color: {text};
    font-family: "Iosevka Nerd Font", "Iosevka", monospace;
    font-size: 12pt;
    caret-color: {accent};
}}

.search-entry:focus, .search-entry:focus-within {{
    background: transparent;
    background-color: transparent;
    border: none;
    outline: none;
    box-shadow: none;
}}

.search-entry text {{
    background: transparent;
    background-color: transparent;
    color: {text};
}}

.search-entry placeholder {{
    color: {muted};
}}

.grid-container {{
    background-color: transparent;
}}

.grid-scroll {{
    background-color: transparent;
}}

flowboxchild {{
    padding: 0;
    margin: 0;
    background: transparent;
    outline: none;
}}

.app-card {{
    background-color: transparent;
    border-radius: 14px;
    padding: 8px 4px;
    margin: 2px;
    outline: none;
    border: 1px solid transparent;
    min-width: 0;
}}

.app-card:hover {{
    background-color: {hover_bg};
}}

.app-card.selected {{
    background-color: {selected_bg};
    border: 1px solid {accent};
}}

.app-icon {{
    margin-bottom: 6px;
}}

.app-label {{
    color: {text};
    font-family: "Iosevka Nerd Font", "Iosevka", monospace;
    font-size: 9.5pt;
    font-weight: 500;
}}

.app-card.selected .app-label {{
    color: #FFFFFF;
    font-weight: 700;
}}
"#,
            name = p.name,
            bg_glass = bg_glass,
            accent_border = accent_border,
            accent = p.accent,
            text = p.text,
            muted = p.muted,
            hover_bg = hover_bg,
            selected_bg = selected_bg,
        )
    }
}

fn parse_palette_object(json: &Value, name: &str, opacity: f32) -> ThemePalette {
    let get_color = |key: &str, fallback: &str| -> String {
        json.get(key)
            .and_then(|v| v.as_str())
            .unwrap_or(fallback)
            .to_string()
    };

    ThemePalette {
        name: name.to_string(),
        background: get_color("background", "#101418"),
        surface0: get_color("surface0", "#1c2024"),
        surface1: get_color("surface1", "#272a2e"),
        surface2: get_color("surface2", "#313539"),
        surface3: get_color("surface3", "#42474e"),
        text: get_color("text", "#e0e2e8"),
        accent: get_color("accent", "#99ccfa"),
        muted: get_color("muted", "#8c9198"),
        opacity,
    }
}

pub fn hex_to_rgba(hex: &str, alpha: f32) -> String {
    let clean = hex.trim_start_matches('#');
    if clean.len() >= 6 {
        let r = u8::from_str_radix(&clean[0..2], 16).unwrap_or(16);
        let g = u8::from_str_radix(&clean[2..4], 16).unwrap_or(20);
        let b = u8::from_str_radix(&clean[4..6], 16).unwrap_or(24);
        format!("rgba({}, {}, {}, {:.2})", r, g, b, alpha)
    } else {
        format!("rgba(16, 20, 24, {:.2})", alpha)
    }
}
