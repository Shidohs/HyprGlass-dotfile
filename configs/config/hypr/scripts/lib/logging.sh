#!/usr/bin/env bash
# HyprGlass - Shared Logging & Helper Utilities
# Clean Code & SOLID principles for Bash scripting

set -euo pipefail

# Prevent double loading
if [[ "${_HYPRGLASS_LOGGING_SH_LOADED:-0}" == "1" ]]; then
    return 0
fi
_HYPRGLASS_LOGGING_SH_LOADED=1

# --- Colors & Styles ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default log file location (can be overridden by caller)
HYPRGLASS_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/logs"
HYPRGLASS_LOG_FILE="${HYPRGLASS_LOG_FILE:-$HYPRGLASS_LOG_DIR/system.log}"

# Ensure log directory exists silently
mkdir -p "$HYPRGLASS_LOG_DIR" 2>/dev/null || true

_log_to_file() {
    local level="$1"
    local msg="$2"
    if [[ -n "${HYPRGLASS_LOG_FILE:-}" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$HYPRGLASS_LOG_FILE" 2>/dev/null || true
    fi
}

log_info() {
    local msg="$1"
    echo -e "${BLUE}${BOLD}[INFO]${NC} ${WHITE}${msg}${NC}"
    _log_to_file "INFO" "$msg"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}${BOLD}[OK]${NC} ${WHITE}${msg}${NC}"
    _log_to_file "SUCCESS" "$msg"
}

log_warn() {
    local msg="$1"
    echo -e "${YELLOW}${BOLD}[WARN]${NC} ${YELLOW}${msg}${NC}" >&2
    _log_to_file "WARN" "$msg"
}

log_error() {
    local msg="$1"
    echo -e "${RED}${BOLD}[ERROR]${NC} ${RED}${msg}${NC}" >&2
    _log_to_file "ERROR" "$msg"
}

log_debug() {
    local msg="$1"
    if [[ "${HYPRGLASS_DEBUG:-false}" == "true" ]]; then
        echo -e "${GRAY}${BOLD}[DEBUG]${NC} ${GRAY}${msg}${NC}" >&2
        _log_to_file "DEBUG" "$msg"
    fi
}

log_step() {
    local msg="$1"
    echo -e "\n${PURPLE}${BOLD}🔸 [STEP]${NC} ${WHITE}${msg}${NC}"
    echo -e "${GRAY}$(printf '─%.0s' {1..60})${NC}"
    _log_to_file "STEP" "$msg"
}

notify_user() {
    local title="$1"
    local body="$2"
    local urgency="${3:-normal}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" "$title" "$body" 2>/dev/null || true
    fi
}

check_cmd() {
    local cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

require_cmds() {
    local missing=()
    for cmd in "$@"; do
        if ! check_cmd "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required command(s): ${missing[*]}"
        return 1
    fi
    return 0
}
