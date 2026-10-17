#!/usr/bin/env bash
# HyprGlass - Wallpaper Control Wrapper

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

ENGINE="$SCRIPT_DIR/AleatoryWall.sh"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/wallpaper"
CURRENT_WALLPAPER_FILE="$STATE_ROOT/current-wallpaper"

current_wallpaper() {
    [[ -f "$CURRENT_WALLPAPER_FILE" ]] || return 1
    cat "$CURRENT_WALLPAPER_FILE"
}

status_output() {
    local backend="${BACKEND:-awww}"
    local current="unset"
    local dep_status="missing"
    local dependency="awww"

    if [[ "$backend" == "mpvpaper" ]]; then
        dependency="mpvpaper"
    elif command -v awww >/dev/null 2>&1; then
        dependency="awww"
    elif command -v swww >/dev/null 2>&1; then
        dependency="swww"
    fi
    if command -v "$dependency" >/dev/null 2>&1; then
        dep_status="ok"
    fi
    if current="$(current_wallpaper 2>/dev/null)"; then
        :
    else
        current="unset"
    fi

    printf 'backend=%s\ndependency=%s:%s\ncurrent=%s\n' \
        "$backend" \
        "$dependency" \
        "$dep_status" \
        "$current"
}

show_status() {
    local output
    output="$(status_output)"
    printf '%s\n' "$output"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Wallpaper Controller" "$output"
    fi
}

apply_change() {
    "$ENGINE" "$@"
    if current="$(current_wallpaper 2>/dev/null)"; then
        log_info "Wallpaper changed to: $(basename "$current")"
    fi
}

apply_set() {
    local target="${1:-}"

    if [[ -z "$target" ]]; then
        log_error "Usage: wallpaper-control.sh set <path>"
        exit 1
    fi

    "$ENGINE" --file "$target"
    if current="$(current_wallpaper 2>/dev/null)"; then
        log_info "Wallpaper set to: $(basename "$current")"
    fi
}

case "${1:-change}" in
    change)
        shift
        apply_change "$@"
        ;;
    set)
        shift
        apply_set "${1:-}"
        ;;
    status)
        show_status
        ;;
    *)
        log_error "Usage: wallpaper-control.sh [change|set <path>|status]"
        exit 1
        ;;
esac
