use std::collections::{HashMap, HashSet};
use std::fs;
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::Command;

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct AppInfo {
    pub id: String,
    pub name: String,
    pub generic_name: Option<String>,
    pub comment: Option<String>,
    pub exec: String,
    pub icon: String,
    pub terminal: bool,
    pub keywords: Vec<String>,
    pub categories: Vec<String>,
}

pub struct AppScanner {
    cache_dirs: Vec<PathBuf>,
    last_mtime: u64,
}

impl AppScanner {
    pub fn new() -> Self {
        let mut dirs = Vec::new();

        if let Some(data_home) = dirs::data_dir() {
            dirs.push(data_home.join("applications"));
        }

        if let Ok(data_dirs) = std::env::var("XDG_DATA_DIRS") {
            for dir in data_dirs.split(':') {
                if !dir.is_empty() {
                    dirs.push(PathBuf::from(dir).join("applications"));
                }
            }
        } else {
            dirs.push(PathBuf::from("/usr/local/share/applications"));
            dirs.push(PathBuf::from("/usr/share/applications"));
        }

        // Flatpak system exports
        let flatpak_system = PathBuf::from("/var/lib/flatpak/exports/share/applications");
        if flatpak_system.exists() && !dirs.contains(&flatpak_system) {
            dirs.push(flatpak_system);
        }

        // Flatpak user exports
        if let Some(home) = dirs::home_dir() {
            let flatpak_user = home.join(".local/share/flatpak/exports/share/applications");
            if flatpak_user.exists() && !dirs.contains(&flatpak_user) {
                dirs.push(flatpak_user);
            }
        }

        Self {
            cache_dirs: dirs,
            last_mtime: 0,
        }
    }

    pub fn check_needs_reload(&self) -> bool {
        let current_max = self.get_latest_mtime();
        current_max > self.last_mtime
    }

    fn get_latest_mtime(&self) -> u64 {
        let mut max_mtime = 0;
        for dir in &self.cache_dirs {
            if let Ok(metadata) = fs::metadata(dir) {
                if let Ok(modified) = metadata.modified() {
                    if let Ok(duration) = modified.duration_since(std::time::UNIX_EPOCH) {
                        max_mtime = max_mtime.max(duration.as_secs());
                    }
                }
            }
        }
        max_mtime
    }

    pub fn scan(&mut self) -> Vec<AppInfo> {
        self.last_mtime = self.get_latest_mtime();
        let mut seen_ids = HashSet::new();
        let mut apps = Vec::new();

        for dir in &self.cache_dirs {
            if !dir.is_dir() {
                continue;
            }

            for entry in walkdir::WalkDir::new(dir)
                .max_depth(3)
                .into_iter()
                .filter_map(|e| e.ok())
            {
                let path = entry.path();
                if path.extension().and_then(|ext| ext.to_str()) != Some("desktop") {
                    continue;
                }

                let id = path
                    .file_name()
                    .and_then(|f| f.to_str())
                    .unwrap_or_default()
                    .to_string();

                if seen_ids.contains(&id) {
                    continue;
                }

                if let Some(app) = parse_desktop_file(path, &id) {
                    seen_ids.insert(id);
                    apps.push(app);
                }
            }
        }

        // Sort alphabetically by name (case-insensitive)
        apps.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
        apps
    }
}

fn parse_desktop_file(path: &Path, id: &str) -> Option<AppInfo> {
    let content = fs::read_to_string(path).ok()?;
    let mut in_desktop_entry = false;
    let mut entries = HashMap::new();

    for line in content.lines() {
        let line = line.trim();
        if line.starts_with('#') || line.is_empty() {
            continue;
        }

        if line.starts_with('[') && line.ends_with(']') {
            let section = &line[1..line.len() - 1];
            in_desktop_entry = section == "Desktop Entry";
            continue;
        }

        if !in_desktop_entry {
            continue;
        }

        if let Some((key, value)) = line.split_once('=') {
            entries.insert(key.trim().to_string(), value.trim().to_string());
        }
    }

    // Type must be Application
    if entries.get("Type").map(|s| s.as_str()) != Some("Application") {
        return None;
    }

    // Must not be hidden or NoDisplay
    if entries.get("NoDisplay").map(|s| s.as_str()) == Some("true") {
        return None;
    }
    if entries.get("Hidden").map(|s| s.as_str()) == Some("true") {
        return None;
    }

    let name = entries.get("Name")?.clone();
    if name.is_empty() {
        return None;
    }

    let exec = entries.get("Exec")?.clone();
    if exec.is_empty() {
        return None;
    }

    // Check TryExec if present
    if let Some(try_exec) = entries.get("TryExec") {
        if !is_command_available(try_exec) {
            return None;
        }
    }

    let icon = entries
        .get("Icon")
        .cloned()
        .unwrap_or_else(|| "application-x-executable".to_string());

    let generic_name = entries.get("GenericName").cloned();
    let comment = entries.get("Comment").cloned();
    let terminal = entries.get("Terminal").map(|s| s == "true").unwrap_or(false);

    let keywords = entries
        .get("Keywords")
        .map(|k| {
            k.split(';')
                .filter(|s| !s.trim().is_empty())
                .map(|s| s.trim().to_string())
                .collect()
        })
        .unwrap_or_default();

    let categories = entries
        .get("Categories")
        .map(|c| {
            c.split(';')
                .filter(|s| !s.trim().is_empty())
                .map(|s| s.trim().to_string())
                .collect()
        })
        .unwrap_or_default();

    Some(AppInfo {
        id: id.to_string(),
        name,
        generic_name,
        comment,
        exec,
        icon,
        terminal,
        keywords,
        categories,
    })
}

fn is_command_available(cmd: &str) -> bool {
    let binary = cmd.split_whitespace().next().unwrap_or(cmd);
    if binary.starts_with('/') {
        return Path::new(binary).exists();
    }
    if let Ok(path_var) = std::env::var("PATH") {
        for p in path_var.split(':') {
            if Path::new(p).join(binary).is_file() {
                return true;
            }
        }
    }
    true
}

pub fn clean_exec(exec_line: &str) -> Vec<String> {
    let mut parts = Vec::new();
    let mut current = String::new();
    let mut in_quotes = false;
    let mut quote_char = ' ';

    for ch in exec_line.chars() {
        match ch {
            '"' | '\'' => {
                if in_quotes && ch == quote_char {
                    in_quotes = false;
                } else if !in_quotes {
                    in_quotes = true;
                    quote_char = ch;
                } else {
                    current.push(ch);
                }
            }
            ' ' | '\t' if !in_quotes => {
                if !current.is_empty() {
                    parts.push(current);
                    current = String::new();
                }
            }
            _ => current.push(ch),
        }
    }
    if !current.is_empty() {
        parts.push(current);
    }

    // Filter out field codes (%f, %F, %u, %U, %d, %D, %n, %N, %i, %c, %k, %v, %m)
    parts
        .into_iter()
        .filter(|part| {
            if part.starts_with('%') && part.len() == 2 {
                false
            } else {
                true
            }
        })
        .collect()
}

pub fn launch_app(app: &AppInfo) -> std::io::Result<()> {
    let mut cmd_parts = clean_exec(&app.exec);
    if cmd_parts.is_empty() {
        return Err(std::io::Error::new(
            std::io::ErrorKind::InvalidInput,
            "Empty exec command",
        ));
    }

    let program;
    let args: Vec<String>;

    if app.terminal {
        // Run inside terminal (kitty by default or $TERMINAL)
        let term = std::env::var("TERMINAL").unwrap_or_else(|_| "kitty".to_string());
        program = term;
        let mut term_args = vec!["-e".to_string()];
        term_args.append(&mut cmd_parts);
        args = term_args;
    } else {
        program = cmd_parts.remove(0);
        args = cmd_parts;
    }

    let mut command = Command::new(program);
    command.args(&args);

    // Detach process into a new session
    unsafe {
        command.pre_exec(|| {
            libc::setsid();
            Ok(())
        });
    }

    command.spawn()?;
    Ok(())
}
