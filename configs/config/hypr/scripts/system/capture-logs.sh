#!/usr/bin/env bash
# HyprGlass - Hyprland Log Capture Script

set -euo pipefail

LOGS_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/logs"
mkdir -p "$LOGS_DIR"

LOG_FILE="$LOGS_DIR/hyprland-$(date +%Y-%m-%d_%H-%M-%S).log"

if command -v Hyprland >/dev/null 2>&1; then
    exec Hyprland > "$LOG_FILE" 2>&1
else
    echo "[ERROR] Hyprland binary not found in PATH." >&2
    exit 1
fi
