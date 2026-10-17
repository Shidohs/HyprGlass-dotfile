# 🚀 Glass Launcher (Rust Native Hyprland Launcher)

Un lanzador de aplicaciones nativo ultra-optimizado escrito en **Rust** con **GTK4 Layer Shell**, diseñado específicamente para reemplazar Rofi en Wayland/Hyprland manteniendo una estética idéntica a `allApps.rasi` con integración en tiempo real para temas de **Quickshell (`qs_dashboard`)** y **Material You (Matugen)**.

## ✨ Características

- **Arquitectura Cliente/Daemon ultrarrápida**:
  - `launcher --daemon`: Se mantiene en segundo plano en memoria consumiendo mínimos recursos.
  - `launcher-ctl`: Binario de control de ~335 KB con IPC sobre socket UNIX (`glass-launcher.sock`) con respuesta en **< 2ms**.
- **Grid de 6 columnas**:
  - Proporción visual perfecta para resoluciones de laptop (1366x768).
  - Iconos de 64px (`BeautyLine`) con bordes redondeados y tipografía Iosevka Nerd Font.
- **Scroll fluido a 60 FPS**:
  - Optimizado para GPUs integradas heredadas (Intel HD Graphics 3000 / Sandy Bridge) y GPU dedicadas.
  - Sin cuellos de botella de shader GPU causados por box-shadows pesados.
- **Sincronización Dinámica de Temas**:
  - Detecta automáticamente el modo de `~/.config/quickshell/data/state/state.json`.
  - **Material You (`mode: "auto"`)**: Lee la paleta generada por Matugen en `~/.cache/matugen/quickshell-palette.json`.
  - **Presets de Color**: Si se selecciona `dracula`, `tokyonight`, `rose-pine`, `sweet`, etc., lee y aplica los colores del tema y la opacidad configurada.
  - Detección de cambios por `mtime` en microsegundos sin recargar ni reiniciar el daemon.

## 📦 Compilación e Instalación

### Dependencias (Arch Linux):
```bash
sudo pacman -S gtk4 gtk4-layer-shell rust cargo
```

### Compilar e instalar:
```bash
./build.sh
```
O manualmente:
```bash
cargo build --release
install -m 755 target/release/launcher ~/.local/bin/launcher
install -m 755 target/release/launcher-ctl ~/.local/bin/launcher-ctl
```

## ⌨️ Uso

- **Alternar visibilidad**: `launcher-ctl toggle`
- **Mostrar**: `launcher-ctl show`
- **Ocultar**: `launcher-ctl hide`
- **Forzar recarga de tema**: `launcher-ctl reload`
- **Cerrar daemon**: `launcher-ctl quit`

## 🔗 Integración con Hyprland

En tu configuración de Hyprland (`lua` o `.conf`):
```lua
-- Atajo de teclado
hl.bind("SUPER + D", hl.dsp.exec_cmd("launcher-ctl toggle"))

-- Autostart daemon
hl.exec_cmd("launcher --daemon")
```
