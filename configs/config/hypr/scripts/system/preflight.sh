#!/usr/bin/env bash
# HyprGlass - Pre-flight Dependency Checker

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [[ -f "$LIB_DIR/logging.sh" ]]; then
    # shellcheck disable=SC1091
    source "$LIB_DIR/logging.sh"
else
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_error() { echo "[ERROR] $1"; }
fi

CRITICAL_DEPS=(
    "hyprland"
    "hyprctl"
    "rofi"
    "notify-send"
    "bc"
    "xdg-user-dir"
    "wl-paste"
    "cliphist"
    "dbus-update-activation-environment"
)

check_deps() {
    local missing=()
    for dep in "${CRITICAL_DEPS[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        local msg="Missing critical dependencies: ${missing[*]}"
        log_error "$msg"
        
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -u critical "HyprGlass Pre-flight Error" "$msg" 2>/dev/null || true
        fi
        
        local log_target="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/preflight.log"
        mkdir -p "$(dirname "$log_target")"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')]: $msg" >> "$log_target"
        return 1
    fi

    log_info "Pre-flight checks passed: all core dependencies available."
    return 0
}

check_deps
