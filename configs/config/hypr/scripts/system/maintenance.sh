#!/usr/bin/env bash
# HyprGlass - System Maintenance Utility

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [[ -f "$LIB_DIR/logging.sh" ]]; then
    # shellcheck disable=SC1091
    source "$LIB_DIR/logging.sh"
else
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_error() { echo "[ERROR] $1"; }
    log_success() { echo "[OK] $1"; }
fi

SUDO=""
if [[ "$EUID" -ne 0 ]]; then
    SUDO="sudo"
fi

clean_caches() {
    log_info "Cleaning system caches..."

    if [[ -d "$HOME/.cache/hyprland" ]]; then
        rm -rf "$HOME/.cache/hyprland"
        log_success "Hyprland cache cleared."
    fi

    if [[ -d "$HOME/.cache/shader-cache" ]]; then
        rm -rf "$HOME/.cache/shader-cache"
        log_success "Shader cache cleared."
    fi

    if [[ -d "$HOME/.cache/thumbnails" ]]; then
        rm -rf "$HOME/.cache/thumbnails"
        log_success "Thumbnails cleared."
    fi

    if [[ -d "$HOME/.cache/fontconfig" ]]; then
        rm -rf "$HOME/.cache/fontconfig"
        log_success "Fontconfig cache cleared."
    fi
}

clean_app_caches() {
    log_info "Cleaning browser and application caches..."

    if [[ -d "$HOME/.cache/mozilla/firefox" ]]; then
        rm -rf "$HOME/.cache/mozilla/firefox"/*.default*/cache2 2>/dev/null || true
        log_success "Firefox cache cleared."
    fi

    if [[ -d "$HOME/.cache/chromium" ]]; then
        rm -rf "$HOME/.cache/chromium"/*/Cache 2>/dev/null || true
        log_success "Chromium cache cleared."
    fi
}

optimize_locales() {
    log_info "Optimizing system locales..."
    if command -v locale-gen >/dev/null 2>&1; then
        $SUDO locale-gen --purge >/dev/null 2>&1 || log_warn "Could not regenerate locales."
    fi
}

clean_orphans() {
    log_info "Searching for orphan packages..."
    if command -v pacman >/dev/null 2>&1; then
        local orphans
        orphans=$(pacman -Qdtq 2>/dev/null || true)
        if [[ -n "$orphans" ]]; then
            log_warn "Orphan packages found: $orphans"
            if [[ "${NON_INTERACTIVE:-false}" != "true" ]]; then
                read -p "Remove orphan packages? (y/N): " -r answer
                if [[ "$answer" =~ ^[Yy]$ ]]; then
                    $SUDO pacman -Rns $orphans
                    log_success "Orphans removed."
                fi
            fi
        else
            log_success "No orphan packages found."
        fi
    fi
}

clean_journal() {
    log_info "Vacuuming systemd journal logs (keeping last 7 days)..."
    if command -v journalctl >/dev/null 2>&1; then
        $SUDO journalctl --vacuum-time=7days >/dev/null 2>&1 || log_warn "Could not vacuum journal."
        log_success "Systemd journal cleaned."
    fi
}

check_user_services() {
    log_info "Restarting user audio services..."
    systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || log_warn "Audio services restart failed."

    if systemctl --user is-active --quiet hypridle 2>/dev/null; then
        log_success "Hypridle service is active."
    else
        log_warn "Hypridle not active. Attempting start..."
        systemctl --user start hypridle 2>/dev/null || true
    fi
}

check_permissions() {
    log_info "Verifying file execution permissions..."
    find "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
    log_success "Script permissions verified."
}

show_stats() {
    log_info "System Performance Overview:"
    echo "Disk Usage:"
    df -h | grep -E "(Filesystem|/dev/)" | head -n 6
    echo
    echo "Memory Usage:"
    free -h
}

main() {
    if [[ "${1:-}" == "auto" ]]; then
        NON_INTERACTIVE=true
        clean_caches
        clean_app_caches
        optimize_locales
        clean_journal
        check_user_services
        check_permissions
        log_success "Automated maintenance finished successfully."
        exit 0
    fi

    echo "🧹 HyprGlass Maintenance System"
    echo "==============================="
    echo "1. Clean system caches"
    echo "2. Clean application caches"
    echo "3. Optimize system locales"
    echo "4. Remove orphan packages"
    echo "5. Vacuum systemd logs"
    echo "6. Verify user services"
    echo "7. Verify permissions"
    echo "8. Display system stats"
    echo "9. Run full maintenance"
    echo "0. Exit"
    echo

    read -p "Select option [1-9]: " -r option
    case "$option" in
        1) clean_caches ;;
        2) clean_app_caches ;;
        3) optimize_locales ;;
        4) clean_orphans ;;
        5) clean_journal ;;
        6) check_user_services ;;
        7) check_permissions ;;
        8) show_stats ;;
        9)
            clean_caches
            clean_app_caches
            optimize_locales
            clean_journal
            check_user_services
            check_permissions
            show_stats
            ;;
        0) exit 0 ;;
        *) log_error "Invalid option" ;;
    esac
}

main "$@"
