#!/usr/bin/env bash
# AleatoryWall.sh - HyprGlass Wallpaper Engine with Matugen/Wallust Color Syncing

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
    log_debug() { echo "[DEBUG] $1"; }
fi

# Configuration
Script_Wall="$(basename "$0")"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/wallpaper"
LOG_FILE="$STATE_ROOT/aleatory-wall.log"
QUEUE_FILE="$STATE_ROOT/queue"
QUEUE_LOCK_FILE="$STATE_ROOT/queue.lock"
CURRENT_WALLPAPER_FILE="$STATE_ROOT/current-wallpaper"
LOCK_WALLPAPER_LINK="$STATE_ROOT/lock-wallpaper"
LOCK_WALLPAPER_STILL="$STATE_ROOT/lock-wallpaper.png"
BACKEND=${BACKEND:-swww} # swww | mpvpaper
OUTPUT=${OUTPUT:-all}    # all | eDP-1 | DP-1 ...

MPV_OPTS=${MPV_OPTS:-"no-audio loop --hwdec=auto-safe --cache=no --scale=bilinear --input-terminal=no"}
MPV_IMAGE_OPTS=${MPV_IMAGE_OPTS:-"no-audio --keep-open=yes --image-display-duration=inf --loop-file=no --hwdec=auto-safe --cache=no --demuxer-max-bytes=5M --demuxer-max-back-bytes=2M"}
MPV_FILL_MODE=${MPV_FILL_MODE:-cover} # cover | fit | stretch
MPVPAPER_AUTO_PAUSE=${MPVPAPER_AUTO_PAUSE:-true}
MPVPAPER_AUTO_STOP=${MPVPAPER_AUTO_STOP:-true}
DEBUG=${DEBUG:-false}
USE_THEME_ENGINE=true

# Default wallpaper directories
WALL_DIRS_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/wallpaper-dirs.conf"
WALL_DIRS=(
    "$HOME/Wallpapers"
    "$HOME/Imágenes/Wallpapers"
    "$HOME/Pictures/Wallpapers"
    "${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers"
)
if [[ -f "$WALL_DIRS_CONF" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        eval line="$line"
        [[ -d "$line" ]] && WALL_DIRS+=("$line")
    done < "$WALL_DIRS_CONF"
fi

SWWW_FORMATS=("*.png" "*.jpg" "*.jpeg" "*.webp" "*.gif" "*.bmp" "*.tiff")
MPVPAPER_FORMATS=("*.png" "*.jpg" "*.jpeg" "*.webp" "*.gif" "*.bmp" "*.tiff" "*.webm" "*.mp4" "*.mkv" "*.mov")

mkdir -p "$STATE_ROOT" 2>/dev/null || true

ensure_queue() {
    if [[ ! -f "$QUEUE_FILE" ]] || [[ ! -s "$QUEUE_FILE" ]]; then
        log_debug "(Re)building wallpaper queue"
        printf '%s\n' "${WALL[@]}" | shuf > "$QUEUE_FILE" || true

        if [[ -f "$CURRENT_WALLPAPER_FILE" ]]; then
            local current
            current=$(cat "$CURRENT_WALLPAPER_FILE" 2>/dev/null || true)
            if [[ -n "$current" ]]; then
                local first
                first=$(head -n 1 "$QUEUE_FILE" 2>/dev/null || true)
                if [[ "$first" == "$current" ]] && [[ $(wc -l < "$QUEUE_FILE") -gt 1 ]]; then
                    tail -n +2 "$QUEUE_FILE" > "$QUEUE_FILE.tmp" && echo "$first" >> "$QUEUE_FILE.tmp" && mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
                fi
            fi
        fi
    fi
}

get_next_wallpaper() {
    local lock_fd
    if command -v flock >/dev/null 2>&1; then
        exec {lock_fd}>"$QUEUE_LOCK_FILE"
        flock -x "$lock_fd"
    fi

    ensure_queue

    local next
    next=$(head -n 1 "$QUEUE_FILE" 2>/dev/null || true)

    if [[ -z "$next" ]]; then
        : > "$QUEUE_FILE" || true
        ensure_queue
        next=$(head -n 1 "$QUEUE_FILE" 2>/dev/null || true)
    fi

    if [[ -z "$next" ]]; then
        if [[ -n "${lock_fd:-}" ]]; then
            flock -u "$lock_fd" 2>/dev/null || true
            exec {lock_fd}>&-
        fi
        return 1
    fi

    tail -n +2 "$QUEUE_FILE" > "$QUEUE_FILE.tmp" 2>/dev/null || true
    mv "$QUEUE_FILE.tmp" "$QUEUE_FILE" 2>/dev/null || true

    if [[ -n "${lock_fd:-}" ]]; then
        flock -u "$lock_fd" 2>/dev/null || true
        exec {lock_fd}>&-
    fi

    echo "$next"
}

load_wallpapers() {
    local -a formats
    if [[ "$BACKEND" == "mpvpaper" ]] || command -v mpvpaper >/dev/null 2>&1; then
        formats=("${MPVPAPER_FORMATS[@]}")
    else
        formats=("${SWWW_FORMATS[@]}")
    fi

    local -a valid_dirs=()
    for dir in "${WALL_DIRS[@]}"; do
        [[ -d "$dir" ]] && valid_dirs+=("$dir")
    done

    mapfile -t WALL < <(
        for format in "${formats[@]}"; do
            find -L "${valid_dirs[@]}" -type f -iname "$format" 2>/dev/null
        done | sort -u
    )
}

load_wallpapers

if [[ ${#WALL[@]} -eq 0 ]]; then
    log_error "No image files found in configured wallpaper directories."
    exit 1
fi

check_dependencies() {
    local missing=()
    if [[ "$BACKEND" == "mpvpaper" ]]; then
        command -v mpvpaper >/dev/null 2>&1 || missing+=("mpvpaper")
    else
        command -v awww >/dev/null 2>&1 || command -v swww >/dev/null 2>&1 || missing+=("awww/swww")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required wallpaper dependency: ${missing[*]}"
        return 1
    fi
    return 0
}

media_kind() {
    local path="$1"
    local ext="${path##*.}"
    ext="${ext,,}"
    case "$ext" in
        gif) echo "gif";;
        png|jpg|jpeg|webp|bmp|tiff) echo "image";;
        webm|mp4|mkv|mov) echo "video";;
        *) echo "video";;
    esac
}

update_lock_wallpaper() {
    local src="$1"
    local kind
    kind=$(media_kind "$src")

    if [[ "$kind" == "image" ]]; then
        ln -sf "$src" "$LOCK_WALLPAPER_LINK" 2>/dev/null || true
        return 0
    fi

    if command -v ffmpeg >/dev/null 2>&1; then
        ffmpeg -hide_banner -loglevel error -y -i "$src" -vframes 1 "$LOCK_WALLPAPER_STILL" >/dev/null 2>&1 || true
        if [[ -f "$LOCK_WALLPAPER_STILL" ]]; then
            ln -sf "$LOCK_WALLPAPER_STILL" "$LOCK_WALLPAPER_LINK" 2>/dev/null || true
        fi
    fi
}

stop_mpvpaper() {
    pkill -x mpvpaper 2>/dev/null || true
}

stop_swww_daemon() {
    pkill -x awww-daemon 2>/dev/null || true
    pkill -x swww-daemon 2>/dev/null || true
    rm -f "/run/user/${UID:-1000}"/*awww-daemon*.sock "/run/user/${UID:-1000}"/*swww-daemon*.sock 2>/dev/null || true
}

ensure_swww_daemon() {
    local daemon_bin="awww-daemon"
    if ! command -v "$daemon_bin" >/dev/null 2>&1; then
        daemon_bin="swww-daemon"
    fi
    if ! pgrep -x "$daemon_bin" >/dev/null 2>&1; then
        rm -f "/run/user/${UID:-1000}"/*awww-daemon*.sock "/run/user/${UID:-1000}"/*swww-daemon*.sock 2>/dev/null || true
        nohup "$daemon_bin" >/dev/null 2>&1 &
        sleep 1.5
    fi
}

update_theme_colors() {
    local wallpaper="$1"
    local color_source="$wallpaper"
    local kind
    kind=$(media_kind "$wallpaper")

    if [[ "$kind" == "video" && -f "$LOCK_WALLPAPER_STILL" ]]; then
        color_source="$LOCK_WALLPAPER_STILL"
    fi

    log_info "Synchronizing color palette from wallpaper..."

    if command -v matugen >/dev/null 2>&1; then
        log_info "Generating colors with Matugen..."
        matugen image "$color_source" --source-color-index 0 >/dev/null 2>&1 || log_warn "Matugen palette generation returned non-zero."
    elif command -v wallust >/dev/null 2>&1; then
        log_info "Generating colors with Wallust..."
        wallust run "$color_source" >/dev/null 2>&1 || log_warn "Wallust palette generation returned non-zero."
    elif command -v wal >/dev/null 2>&1; then
        log_info "Generating colors with Pywal..."
        wal -i "$color_source" --backend wal -q >/dev/null 2>&1 || true
    fi

    local unifier="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/system/theme-unifier.sh"
    if [[ -f "$unifier" ]]; then
        "$unifier" reload >/dev/null 2>&1 || true
    fi
}

apply_wallpaper() {
    local wallpaper="$1"
    local wallpaper_name
    wallpaper_name=$(basename "$wallpaper")

    log_info "Setting wallpaper: $wallpaper_name"

    if [[ ! -f "$wallpaper" || ! -r "$wallpaper" ]]; then
        log_error "Cannot read wallpaper file: $wallpaper"
        return 1
    fi

    local kind
    kind=$(media_kind "$wallpaper")

    if [[ "$kind" == "video" || "$BACKEND" == "mpvpaper" ]]; then
        stop_swww_daemon
        stop_mpvpaper
        local mpvpaper_output="$OUTPUT"
        [[ "$mpvpaper_output" == "all" ]] && mpvpaper_output="*"
        local auto_opts=""
        [[ "$MPVPAPER_AUTO_PAUSE" == "true" ]] && auto_opts="-p"
        nohup setsid mpvpaper $auto_opts -o "$MPV_OPTS" "$mpvpaper_output" "$wallpaper" </dev/null >/dev/null 2>&1 &
        disown $! 2>/dev/null || true
    else
        stop_mpvpaper
        ensure_swww_daemon
        local client_bin="awww"
        if ! command -v "$client_bin" >/dev/null 2>&1; then
            client_bin="swww"
        fi
        "$client_bin" img "$wallpaper" --transition-type wipe --transition-duration 1.5 >/dev/null 2>&1 || return 1
    fi

    log_success "Wallpaper updated to: $wallpaper_name"
    echo "$wallpaper" > "$CURRENT_WALLPAPER_FILE" 2>/dev/null || true
    update_lock_wallpaper "$wallpaper"

    if [[ "$USE_THEME_ENGINE" == "true" ]]; then
        update_theme_colors "$wallpaper"
    fi
}

change_wallpaper() {
    local wallpaper
    wallpaper=$(get_next_wallpaper) || {
        log_error "Failed to retrieve next wallpaper from queue"
        return 1
    }
    apply_wallpaper "$wallpaper"
}

main() {
    check_dependencies || exit 1

    local requested_file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --debug)
                DEBUG=true
                shift
                ;;
            --file)
                requested_file="${2:-}"
                shift 2
                ;;
            --backend)
                BACKEND="${2:-}"
                shift 2
                ;;
            --output)
                OUTPUT="${2:-all}"
                shift 2
                ;;
            --once|change)
                shift
                ;;
            --pywal|-p|--theme)
                USE_THEME_ENGINE=true
                shift
                ;;
            --help|-h)
                cat << EOF
AleatoryWall - HyprGlass Wallpaper Engine
Usage: $0 [OPTIONS]
  --file PATH         Apply specific wallpaper file.
  --backend swww|mpvpaper
  --output OUTPUT     Target monitor output (default: all).
  --pywal, -p         Sync color palette with Matugen/Wallust/Pywal.
  --help, -h          Show help message.
EOF
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                exit 1
                ;;
        esac
    done

    if [[ -n "$requested_file" ]]; then
        local target="$requested_file"
        if [[ ! -f "$target" && -f "$WALL_DIR/$target" ]]; then
            target="$WALL_DIR/$target"
        fi
        apply_wallpaper "$target"
        exit 0
    fi

    change_wallpaper
}

main "$@"
