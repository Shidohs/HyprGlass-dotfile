#!/usr/bin/env bash
# HyprGlass - Unified Screen Lock Entrypoint

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

if command -v hyprlock >/dev/null 2>&1; then
    exec hyprlock --immediate
fi

if command -v swaylock-fancy >/dev/null 2>&1; then
    exec swaylock-fancy
fi

if command -v swaylock >/dev/null 2>&1; then
    exec swaylock -f -c 000000
fi

log_error "No lock screen utility found (hyprlock or swaylock required)."
exit 127
