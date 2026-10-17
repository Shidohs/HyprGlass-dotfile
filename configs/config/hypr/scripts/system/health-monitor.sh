#!/usr/bin/env bash
# HyprGlass - System Health Monitor

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [[ -f "$LIB_DIR/logging.sh" ]]; then
    # shellcheck disable=SC1091
    source "$LIB_DIR/logging.sh"
fi

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
LOG_FILE="$STATE_DIR/health.log"

mkdir -p "$STATE_DIR"

check_hyprland_health() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    {
        echo "[$timestamp] Health Check"

        if pgrep -x "Hyprland" >/dev/null 2>&1; then
            echo "✅ Hyprland: Running"
        else
            echo "❌ Hyprland: Not running"
            return 1
        fi

        local mem_usage
        mem_usage=$(ps -o %mem= -p "$(pgrep -x Hyprland | head -n 1)" 2>/dev/null | tr -d ' ' || echo "0")
        echo "📊 Hyprland Memory usage: ${mem_usage}%"

        local launcher_script="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/start-quickshell.sh"

        for component in quickshell waybar rofi hypridle; do
            if pgrep -x "$component" >/dev/null 2>&1; then
                echo "✅ $component: Running"
            else
                echo "⚠️  $component: Not running"
                case "$component" in
                    quickshell|waybar)
                        if [[ -x "$launcher_script" ]]; then
                            echo " Attempting bar restart..."
                            "$launcher_script" >/dev/null 2>&1 &
                        fi
                        ;;
                    hypridle)
                        if command -v hypridle >/dev/null 2>&1; then
                            echo " Attempting hypridle restart..."
                            hypridle >/dev/null 2>&1 &
                        fi
                        ;;
                esac
            fi
        done

        echo "---"

    } >> "$LOG_FILE"
}

check_hyprland_health

if [[ -f "$LOG_FILE" ]]; then
    tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
