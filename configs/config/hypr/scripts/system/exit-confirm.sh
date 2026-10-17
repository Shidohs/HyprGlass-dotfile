#!/usr/bin/env bash
# Exit / Power confirmation dialog for Hyprland

CANCEL="󰜺  Cancelar"
LOGOUT="󰍃  Cerrar sesión de Hyprland"
REBOOT="󰜉  Reiniciar equipo"
POWEROFF="󰐥  Apagar equipo"
SUSPEND="󰒲  Suspender"

OPTIONS="${CANCEL}\n${LOGOUT}\n${REBOOT}\n${POWEROFF}\n${SUSPEND}"

if command -v rofi >/dev/null 2>&1; then
    CHOSEN=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "  Acción de sesión: " \
        -theme-str 'window {width: 340px; padding: 15px; border-radius: 12px;} listview {lines: 5; scrollbar: false;} element {padding: 8px;}')
elif command -v zenity >/dev/null 2>&1; then
    if zenity --question --title="Cerrar Sesión" --text="¿Deseas salir de la sesión de Hyprland?" --ok-label="Salir" --cancel-label="Cancelar"; then
        CHOSEN="$LOGOUT"
    else
        CHOSEN="$CANCEL"
    fi
fi

case "$CHOSEN" in
    "$LOGOUT")
        hyprctl dispatch exit
        ;;
    "$REBOOT")
        systemctl reboot
        ;;
    "$POWEROFF")
        systemctl poweroff
        ;;
    "$SUSPEND")
        systemctl suspend
        ;;
    *)
        exit 0
        ;;
esac
