#!/usr/bin/env bash
# HyprGlass - Idle Daemon Launcher
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

LOCK_CMD="$SCRIPT_DIR/lock.sh"

if command -v hypridle >/dev/null 2>&1; then
    log_info "Launching hypridle..."
    exec hypridle
elif command -v swayidle >/dev/null 2>&1; then
    log_info "Launching swayidle fallback..."
    exec swayidle -w \
        timeout 6600 "$LOCK_CMD" \
        timeout 7200 "wlopm --off '*'" resume "wlopm --on '*'" \
        before-sleep "$LOCK_CMD" \
        after-resume "wlopm --on '*'"
else
    log_error "No idle daemon found (hypridle or swayidle required)."
    exit 127
fi
