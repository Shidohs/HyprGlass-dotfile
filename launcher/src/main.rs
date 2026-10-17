mod apps;
mod config;
mod daemon;
mod search;
mod theme;
mod ui;

use gtk4::glib;
use gtk4::prelude::*;
use std::io::{BufRead, BufReader, Write};

fn main() -> glib::ExitCode {
    let args: Vec<String> = std::env::args().collect();
    let command = args.get(1).map(|s| s.as_str()).unwrap_or("toggle");

    let allow_standalone = std::env::var("GLASS_LAUNCHER_STANDALONE").map(|v| v == "1").unwrap_or(false);

    // 1. If explicit client command: try to talk to existing daemon first
    if !allow_standalone {
        match command {
            "toggle" | "--toggle" | "-t" => {
                if daemon::send_command("toggle").is_ok() {
                    return glib::ExitCode::SUCCESS;
                }
                // If daemon is not running, fall through and run standalone
            }
            "show" | "--show" | "-s" => {
                if daemon::send_command("show").is_ok() {
                    return glib::ExitCode::SUCCESS;
                }
            }
            "hide" | "--hide" => {
                if daemon::send_command("hide").is_ok() {
                    return glib::ExitCode::SUCCESS;
                }
                return glib::ExitCode::SUCCESS;
            }
            "reload" | "--reload" | "-r" => {
                let _ = daemon::send_command("reload");
                return glib::ExitCode::SUCCESS;
            }
            "quit" | "--quit" => {
                let _ = daemon::send_command("quit");
                return glib::ExitCode::SUCCESS;
            }
            _ => {}
        }
    }

    let is_daemon = command == "daemon" || command == "--daemon" || command == "-d";
    let start_show = is_daemon && args.iter().any(|a| a == "--show" || a == "-s");

    // 2. Enforce strictly single instance via kernel flock (unless explicitly isolated standalone)
    let _lock_file = if allow_standalone {
        None
    } else {
        match daemon::try_acquire_lock() {
            Some(file) => Some(file),
            None => {
                // Another instance is already active or initializing.
                // Forward command to it and exit immediately.
                for _ in 0..10 {
                    if daemon::send_command(command).is_ok() {
                        break;
                    }
                    std::thread::sleep(std::time::Duration::from_millis(40));
                }
                return glib::ExitCode::SUCCESS;
            }
        }
    };

    let as_window = std::env::var("GLASS_LAUNCHER_WINDOW").map(|v| v == "1").unwrap_or(false)
        || args.iter().any(|a| a == "--window" || a == "-w");

    // 3. Initialize GTK4 Application
    let app_id = if as_window {
        "org.antigravity.glass_launcher"
    } else if is_daemon {
        "org.antigravity.glass_launcher.daemon"
    } else if allow_standalone {
        "org.antigravity.glass_launcher.standalone.isolated"
    } else {
        "org.antigravity.glass_launcher.standalone"
    };

    let app = gtk4::Application::builder()
        .application_id(app_id)
        .flags(gio::ApplicationFlags::NON_UNIQUE)
        .build();

    app.connect_activate(move |app| {
        let ui = ui::LauncherUi::new(app, is_daemon);

        if is_daemon {
            if start_show {
                ui.show();
            }

            // Bind daemon socket
            match daemon::DaemonServer::bind() {
                Ok(server) => {
                    let (sender, receiver) = async_channel::unbounded::<String>();

                    std::thread::spawn(move || {
                        while let Ok(stream) = server.accept() {
                            let mut stream = stream;
                            let mut reader = BufReader::new(&stream);
                            let mut line = String::new();
                            if reader.read_line(&mut line).is_ok() {
                                let cmd = line.trim().to_string();
                                let _ = stream.write_all(b"ok\n");
                                let _ = stream.flush();
                                if cmd != "ping" && !cmd.is_empty() {
                                    let _ = sender.send_blocking(cmd);
                                }
                            }
                        }
                    });

                    let ui_clone = ui.clone();
                    let app_clone = app.clone();
                    glib::spawn_future_local(async move {
                        while let Ok(cmd) = receiver.recv().await {
                            match cmd.as_str() {
                                "toggle" => ui_clone.toggle(),
                                "show" => ui_clone.show(),
                                "hide" => ui_clone.hide(),
                                "reload" => ui_clone.reload_theme(),
                                "quit" => {
                                    app_clone.quit();
                                }
                                _ => {}
                            }
                        }
                    });
                }
                Err(err) => {
                    eprintln!("Failed to start daemon socket: {}", err);
                }
            }
        } else {
            // Standalone mode: show immediately
            ui.show();
        }
    });

    app.run_with_args::<String>(&[])
}
