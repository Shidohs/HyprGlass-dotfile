use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::UnixStream;
use std::os::unix::process::CommandExt;
use std::path::PathBuf;
use std::process::Command;

fn get_socket_path() -> PathBuf {
    if let Ok(runtime_dir) = std::env::var("XDG_RUNTIME_DIR") {
        PathBuf::from(runtime_dir).join("glass-launcher.sock")
    } else {
        PathBuf::from(format!("/tmp/glass-launcher-{}.sock", unsafe { libc::getuid() }))
    }
}

fn send_command(cmd: &str) -> std::io::Result<String> {
    let sock_path = get_socket_path();
    let mut stream = UnixStream::connect(sock_path)?;
    stream.write_all(format!("{}\n", cmd).as_bytes())?;
    stream.flush()?;

    let mut reader = BufReader::new(&stream);
    let mut response = String::new();
    reader.read_line(&mut response)?;
    Ok(response.trim().to_string())
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let command = args.get(1).map(|s| s.as_str()).unwrap_or("toggle");

    // Try communicating with daemon
    if send_command(command).is_ok() {
        return;
    }

    // If daemon is not running and command is toggle/show: launch daemon in background with --show
    if command == "toggle" || command == "show" {
        unsafe {
            let _ = Command::new("launcher")
                .arg("--daemon")
                .arg("--show")
                .pre_exec(|| {
                    libc::setsid();
                    Ok(())
                })
                .spawn();
        }
    }
}
