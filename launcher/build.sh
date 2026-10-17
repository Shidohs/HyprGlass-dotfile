#!/usr/bin/env bash
# Build and install Fast Glass Launcher to ~/.local/bin/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Building Glass Launcher (Release mode)..."
cargo build --release

echo "==> Installing binaries to ~/.local/bin/..."
mkdir -p "$HOME/.local/bin"
install -m 755 target/release/launcher "$HOME/.local/bin/launcher"
install -m 755 target/release/launcher-ctl "$HOME/.local/bin/launcher-ctl"

echo "==> Done! Installed:"
ls -lh "$HOME/.local/bin/launcher" "$HOME/.local/bin/launcher-ctl"
