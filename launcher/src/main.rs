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

    // 1. If explicit client command: try to talk to existing daemon first
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

    let is_daemon = command == "daemon" || command == "--daemon" || command == "-d";
    let start_show = is_daemon && args.iter().any(|a| a == "--show" || a == "-s");

    // 2. Initialize GTK4 Application
    let app_id = if is_daemon {
        "org.antigravity.glass_launcher.daemon"
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
                                let _ = sender.send_blocking(cmd);
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
