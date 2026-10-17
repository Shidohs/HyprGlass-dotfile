use std::path::PathBuf;

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct Config {
    pub columns: u32,
    pub icon_size: i32,
    pub icon_theme: String,
    pub font_family: String,
    pub font_size_pt: u32,
    pub placeholder: String,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            columns: 6,
            icon_size: 64, // 64px for 6 columns layout
            icon_theme: "BeautyLine".to_string(),
            font_family: "Iosevka Nerd Font".to_string(),
            font_size_pt: 10,
            placeholder: "Search...".to_string(),
        }
    }
}

pub fn get_user_css_path() -> Option<PathBuf> {
    dirs::config_dir().map(|c| c.join("glass-launcher").join("style.css"))
}

#[allow(dead_code)]
pub fn default_css() -> &'static str {
    r#"
/* Window transparent root */
window, window.launcher-window {
    background-color: transparent;
    background: transparent;
}

/* Glass overlay covering the screen */
.main-wrapper {
    background-color: rgba(3, 3, 21, 0.78);
    padding: 56px 32px 16px 32px;
}

/* Centered Top Search Bar */
.search-container {
    background-color: rgba(255, 255, 255, 0.07);
    border: 1px solid rgba(191, 114, 169, 0.4);
    border-radius: 12px;
    padding: 10px 20px;
    margin-bottom: 20px;
}

.search-icon {
    color: #BF72A9;
    font-family: "Iosevka Nerd Font", "Symbols Nerd Font Mono", monospace;
    font-size: 14pt;
    margin-right: 10px;
}

.search-entry {
    background: transparent;
    background-color: transparent;
    border: none;
    outline: none;
    box-shadow: none;
    color: #E6E1E8;
    font-family: "Iosevka Nerd Font", "Iosevka", monospace;
    font-size: 12pt;
    caret-color: #BF72A9;
}

.search-entry:focus, .search-entry:focus-within {
    background: transparent;
    background-color: transparent;
    border: none;
    outline: none;
    box-shadow: none;
}

.search-entry text {
    background: transparent;
    background-color: transparent;
    color: #E6E1E8;
}

.search-entry placeholder {
    color: #8573B2;
}

/* Grid & ScrolledWindow */
.grid-container {
    background-color: transparent;
}

.grid-scroll {
    background-color: transparent;
}

flowboxchild {
    padding: 0;
    margin: 0;
    background: transparent;
    outline: none;
}

/* Individual App Card - Optimized for 60FPS fluid scrolling without GPU bottlenecks */
.app-card {
    background-color: transparent;
    border-radius: 14px;
    padding: 8px 4px;
    margin: 2px;
    outline: none;
    border: 1px solid transparent;
    min-width: 0;
}

.app-card:hover {
    background-color: rgba(255, 255, 255, 0.08);
}

.app-card.selected {
    background-color: #7D5BA6;
    border: 1px solid #BF72A9;
}

.app-icon {
    margin-bottom: 6px;
}

.app-label {
    color: #E6E1E8;
    font-family: "Iosevka Nerd Font", "Iosevka", monospace;
    font-size: 9.5pt;
    font-weight: 500;
}

.app-card.selected .app-label {
    color: #FFFFFF;
    font-weight: 700;
}
"#
}
