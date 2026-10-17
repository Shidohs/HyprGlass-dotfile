use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::{UnixListener, UnixStream};
use std::path::PathBuf;

pub fn get_socket_path() -> PathBuf {
    if let Ok(runtime_dir) = std::env::var("XDG_RUNTIME_DIR") {
        PathBuf::from(runtime_dir).join("glass-launcher.sock")
    } else {
        PathBuf::from(format!("/tmp/glass-launcher-{}.sock", unsafe { libc::getuid() }))
    }
}

pub fn get_lock_path() -> PathBuf {
    if let Ok(runtime_dir) = std::env::var("XDG_RUNTIME_DIR") {
        PathBuf::from(runtime_dir).join("glass-launcher.lock")
    } else {
        PathBuf::from(format!("/tmp/glass-launcher-{}.lock", unsafe { libc::getuid() }))
    }
}

pub fn try_acquire_lock() -> Option<std::fs::File> {
    let lock_path = get_lock_path();
    let file = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false)
        .open(&lock_path)
        .ok()?;

    use std::os::unix::io::AsRawFd;
    let ret = unsafe { libc::flock(file.as_raw_fd(), libc::LOCK_EX | libc::LOCK_NB) };
    if ret == 0 {
        Some(file)
    } else {
        None
    }
}

pub fn send_command(cmd: &str) -> std::io::Result<String> {
    let sock_path = get_socket_path();
    let mut stream = UnixStream::connect(sock_path)?;
    stream.write_all(format!("{}\n", cmd).as_bytes())?;
    stream.flush()?;

    let mut reader = BufReader::new(&stream);
    let mut response = String::new();
    reader.read_line(&mut response)?;
    Ok(response.trim().to_string())
}

pub struct DaemonServer {
    listener: UnixListener,
}

impl DaemonServer {
    pub fn bind() -> std::io::Result<Self> {
        let sock_path = get_socket_path();
        if sock_path.exists() {
            // Check if another instance is actually responding
            if send_command("ping").is_ok() {
                return Err(std::io::Error::new(
                    std::io::ErrorKind::AddrInUse,
                    "Another daemon instance is already active",
                ));
            }
            // Stale socket, remove it
            let _ = std::fs::remove_file(&sock_path);
        }

        let listener = UnixListener::bind(&sock_path)?;
        Ok(Self { listener })
    }

    pub fn accept(&self) -> std::io::Result<UnixStream> {
        let (stream, _) = self.listener.accept()?;
        Ok(stream)
    }
}

impl Drop for DaemonServer {
    fn drop(&mut self) {
        let sock_path = get_socket_path();
        let _ = std::fs::remove_file(sock_path);
    }
}
