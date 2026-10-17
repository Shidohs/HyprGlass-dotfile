#!/usr/bin/env bash
# HyprGlass - Polkit Authentication Agent Launcher

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

candidates=(
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
    "/usr/libexec/polkit-gnome-authentication-agent-1"
    "polkit-gnome-authentication-agent-1"
    "/usr/lib/polkit-kde-authentication-agent-1"
    "polkit-kde-authentication-agent-1"
    "/usr/lib/lxqt-policykit-agent"
    "lxqt-policykit-agent"
    "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1"
)

for candidate in "${candidates[@]}"; do
    resolved=""
    if [[ "$candidate" == /* ]]; then
        [[ -x "$candidate" ]] && resolved="$candidate"
    else
        resolved="$(command -v "$candidate" 2>/dev/null || true)"
    fi

    if [[ -n "$resolved" && -x "$resolved" ]]; then
        base_name="$(basename "$resolved")"
        if pgrep -f "$base_name" >/dev/null 2>&1; then
            log_info "Polkit agent already running ($base_name)."
            exit 0
        fi

        log_info "Launching Polkit agent: $resolved"
        "$resolved" >/dev/null 2>&1 &
        exit 0
    fi
done

log_warn "No graphical Polkit authentication agent found."
exit 0
