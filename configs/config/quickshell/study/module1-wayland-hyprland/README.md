# Modulo 1: Fundamentos de Wayland e Hyprland IPC

## Objetivos

Al completar este modulo, podras:
- Explicar la diferencia entre X11 y Wayland.
- Describir como funciona un compositor Wayland.
- Leer eventos de Hyprland directamente desde su socket UNIX.
- Enviar comandos a Hyprland sin usar `hyprctl`.

## 1.1 Wayland vs X11

### X11 (X Window System)
- Arquitectura cliente-servidor donde el servidor X maneja todo.
- El servidor tiene acceso a toda la memoria de las ventanas (problema de seguridad).
- Sin soporte nativo para composicion moderna (blur, sombras, animaciones).
- Protocolo con decadas de extensions acumuladas (Xrandr, Xinerama, etc).

### Wayland
- El compositor ES el servidor. No hay separacion.
- Cada cliente solo conoce su propia ventana (seguridad por diseno).
- Protocolo minimalista y extensible.
- Soporte nativo para superficies, buffers compartidos (shm), input.

```
X11:  App --> Servidor X --> Compositor (opcional) --> Pantalla
Wayland: App --> Compositor (que tambien es servidor) --> Pantalla
```

## 1.2 El Compositor Hyprland

Hyprland es un compositor Wayland con tiling automatico. Provee:
- Gestion de ventanas (tiling, floating, layers).
- Protocolos Wayland propios y estandar (wlr-layer-shell, xdg-shell).
- IPC completo via sockets UNIX.

### Sockets de Hyprland

Hyprland expone dos sockets en `/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/`:

| Socket | Uso |
|--------|-----|
| `.socket.sock` | Enviar comandos (cambiar workspace, mover ventana, etc.) |
| `.socket2.sock` | Recibir eventos (cambio de workspace, ventana activa, etc.) |

## 1.3 Como funciona el IPC

### Leer eventos (socket2)

El socket2 envia eventos como texto plano, separados por lineas:

```
workspacev2>>1
activewindowv2>>kitty,~/HyprGlass-dotfile
monitoraddedv2>>DP-1,DESC
```

### Enviar comandos (socket)

Se envian comandos como strings:

```
dispatch exec kitty
keyword layerrule blur,quickshell
```

## Ejercicios

### Ejercicio 1.1: Explorar sockets
Navega a `/tmp/hypr/` y encuentra los sockets de tu instancia actual.

### Ejercicio 1.2: Leer eventos manualmente
Abre una terminal y ejecuta:
```bash
socat - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock
```
Luego cambia de workspace y observa el evento.

### Ejercicio 1.3: Enviar un comando
```bash
echo "dispatch exec xeyes" | socat - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock
```

### Ejercicio 1.4: Script Python para escuchar eventos
Crea un script Python que se conecte al socket2 y imprima eventos con timestamp.

### Ejercicio 1.5: Analizar el proyecto actual
Busca en `services/` donde se usa `Process {}` para llamar a `hyprctl`. Identifica cuantas veces se podria reemplazar con lectura directa del socket.
