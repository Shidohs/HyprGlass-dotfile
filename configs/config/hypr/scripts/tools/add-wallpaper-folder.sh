#!/usr/bin/env bash
# Script para agregar carpetas de fondos a HyprGlass / Quickshell

CONF_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/wallpaper-dirs.conf"
mkdir -p "$(dirname "$CONF_FILE")"
touch "$CONF_FILE"

TARGET_DIR="${1:-}"

if [[ -z "$TARGET_DIR" ]]; then
    if command -v zenity >/dev/null 2>&1; then
        TARGET_DIR=$(zenity --file-selection --directory --title="Seleccionar carpeta de fondos de pantalla" 2>/dev/null)
    elif command -v kdialog >/dev/null 2>&1; then
        TARGET_DIR=$(kdialog --getexistingdirectory ~ 2>/dev/null)
    fi
fi

if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
    exit 0
fi

# Normalizar ruta absoluta
TARGET_DIR=$(readlink -f "$TARGET_DIR")

# Verificar si ya existe en la lista
if grep -Fxq "$TARGET_DIR" "$CONF_FILE" 2>/dev/null; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Wallpapers" "La carpeta ya está en la lista:\n$TARGET_DIR"
    fi
    exit 0
fi

# Agregar al archivo de configuración
echo "$TARGET_DIR" >> "$CONF_FILE"

# Notificar
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Wallpapers" "Nueva carpeta agregada:\n$TARGET_DIR"
fi

# Notificar a Quickshell para refrescar wallpapers si está corriendo
if [[ -n "${XDG_RUNTIME_DIR:-}" && -f "$XDG_RUNTIME_DIR/quickshell-command" ]]; then
    echo "wallpaper_refresh $(date +%s%N)" >> "$XDG_RUNTIME_DIR/quickshell-command"
fi

# Generar miniaturas en segundo plano con baja prioridad para no saturar CPU
nohup bash "$HOME/.config/hypr/scripts/tools/generate-thumbnails.sh" >/dev/null 2>&1 &

echo "Carpeta agregada exitosamente: $TARGET_DIR"

