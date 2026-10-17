#!/usr/bin/env bash
# HyprGlass - XDG Desktop Portal Initialization & Environment Sync

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

sleep 1

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    export XDG_CURRENT_DESKTOP="Hyprland"
    export XDG_SESSION_DESKTOP="Hyprland"
fi

export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-Hyprland}"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-Hyprland}"

log_info "Synchronizing portal environment variables..."

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP 2>/dev/null || true
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP 2>/dev/null || true
    systemctl --user stop xdg-desktop-portal-hyprland.service xdg-desktop-portal-wlr.service xdg-desktop-portal.service 2>/dev/null || true
fi

# Terminate stale portal instances safely
pkill -f "xdg-desktop-portal" 2>/dev/null || true
sleep 0.5

log_info "Restarting portal services..."
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user restart xdg-desktop-portal-hyprland.service 2>/dev/null || true
    sleep 0.5
    systemctl --user restart xdg-desktop-portal.service 2>/dev/null || true
    log_info "XDG Desktop Portals initialized successfully."
fi
