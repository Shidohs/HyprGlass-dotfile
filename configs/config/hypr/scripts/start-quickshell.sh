#!/usr/bin/env bash
# HyprGlass - Quickshell & Bar Launcher with Waybar Fallback

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

if [[ -f "$LIB_DIR/logging.sh" ]]; then
    source "$LIB_DIR/logging.sh"
else
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_error() { echo "[ERROR] $1"; }
fi

LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/logs/bar.log"
mkdir -p "$(dirname "$LOG_FILE")"

launch_bar() {
    log_info "Initializing desktop panel / status bar..."

    # Kill existing instances of quickshell and waybar
    pkill -x quickshell 2>/dev/null || true
    pkill -x waybar 2>/dev/null || true
    sleep 0.3

    if command -v quickshell >/dev/null 2>&1; then
        log_info "Starting Quickshell bar..."
        exec quickshell "$@"
    elif command -v waybar >/dev/null 2>&1; then
        log_warn "Quickshell not found. Falling back to Waybar..."
        exec waybar "$@"
    else
        log_error "Neither Quickshell nor Waybar is installed on the system."
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -u critical "HyprGlass Error" "Neither Quickshell nor Waybar is installed!"
        fi
        exit 1
    fi
}

{
    echo "=== Bar Launcher Started [$(date '+%Y-%m-%d %H:%M:%S')] ==="
    launch_bar "$@"
} >> "$LOG_FILE" 2>&1