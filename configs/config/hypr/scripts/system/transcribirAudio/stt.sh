#!/usr/bin/env bash
# HyprGlass - Voice Dictation (Speech-to-Text) with Python Venv Isolation

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../../lib"

if [[ -f "$LIB_DIR/logging.sh" ]]; then
    # shellcheck disable=SC1091
    source "$LIB_DIR/logging.sh"
else
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_error() { echo "[ERROR] $1"; }
fi

# Paths & Virtual Environment Isolation
VENV_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hypr/venv_stt"
WHISPER_BIN="${WHISPER_BIN:-${XDG_DATA_HOME:-$HOME/.local/share}/whisper.cpp/bin/whisper-cli}"
WHISPER_MODEL="${WHISPER_MODEL:-${MODEL_PATH:-${XDG_DATA_HOME:-$HOME/.local/share}/whisper.cpp/models/ggml-base-q5_1.bin}}"
AUDIO="/tmp/stt.wav"
LOCK="/tmp/stt.lock"
PID_FILE="/tmp/stt.pid"

notify() {
    local duration="$1"
    local message="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t "$duration" \
            -h string:x-canonical-private-synchronous:stt \
            "Dictado por Voz" "$message" 2>/dev/null || true
    fi
}

ensure_python_venv() {
    if command -v python3 >/dev/null 2>&1; then
        if [[ ! -d "$VENV_DIR" ]]; then
            log_info "Initializing isolated STT Python virtual environment at $VENV_DIR..."
            python3 -m venv "$VENV_DIR" >/dev/null 2>&1 || true
            if [[ -f "$VENV_DIR/bin/pip" && -f "$SCRIPT_DIR/requeriments.txt" ]]; then
                "$VENV_DIR/bin/pip" install --quiet --upgrade pip 2>/dev/null || true
            fi
        fi
    fi
}

check_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        notify 4000 "❌ Falta dependencia: $cmd"
        log_error "Missing required STT dependency: $cmd"
        exit 1
    fi
}

check_binary() {
    local binary="$1"
    if command -v "$binary" >/dev/null 2>&1 || [[ -x "$binary" ]]; then
        return 0
    fi
    notify 5000 "❌ Falta WHISPER_BIN. Define WHISPER_BIN o instala whisper-cli."
    log_error "Missing WHISPER_BIN at: $binary"
    exit 1
}

# Toggle: stop recording if active
if [[ -f "$LOCK" ]]; then
    if [[ -f "$PID_FILE" ]]; then
        pid=$(cat "$PID_FILE" 2>/dev/null || true)
        if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            notify 2000 "🛑 Grabación detenida"
        fi
    fi
    rm -f "$LOCK" "$PID_FILE"
    exit 0
fi

# Validation
check_cmd pw-record
check_cmd wtype
check_binary "$WHISPER_BIN"
ensure_python_venv

if [[ ! -f "$WHISPER_MODEL" ]]; then
    notify 5000 "❌ Falta WHISPER_MODEL en: $WHISPER_MODEL"
    log_error "Whisper model not found at $WHISPER_MODEL"
    exit 1
fi

WHISPER_THREADS="${WHISPER_THREADS:-$(nproc 2>/dev/null || echo 1)}"
WHISPER_OPTS="${WHISPER_OPTS:--nt --no-lms --no-timestamps}"

touch "$LOCK"

cleanup() {
    rm -f "$LOCK" "$PID_FILE"
}
trap cleanup EXIT

notify 60000 "🎤 Grabando... (pulsa otra vez para detener)"

pw-record --channels 1 --rate 16000 "$AUDIO" &
REC_PID=$!
echo "$REC_PID" > "$PID_FILE"

wait "$REC_PID" 2>/dev/null || true
rm -f "$LOCK" "$PID_FILE"

notify 10000 "🧠 Transcribiendo..."

TEXT=$(
    "$WHISPER_BIN" -m "$WHISPER_MODEL" -f "$AUDIO" -l es -t "$WHISPER_THREADS" $WHISPER_OPTS 2>/dev/null \
    | awk '!/^\[/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); if (length($0)) line = line $0 " " } END { gsub(/^[[:space:]]+|[[:space:]]+$/, "", line); if (length(line)) print line }'
)

rm -f "$AUDIO" 2>/dev/null || true

if [[ -z "$TEXT" ]]; then
    notify 3000 "⚠️ No se detectó voz"
    exit 0
fi

wtype "$TEXT"
notify 2000 "✅ Texto insertado"
