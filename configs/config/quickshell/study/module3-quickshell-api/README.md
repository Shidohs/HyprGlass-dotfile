# Modulo 3: API de Quickshell

## Objetivos

- Entender los tipos de ventana de Quickshell (ShellRoot, Panel, Window).
- Usar los modulos integrados de Quickshell.
- Gestionar procesos externos sin bloquear la UI.
- Configurar ventanas para Wayland/Hyprland.

## 3.1 Tipos de Ventana

Quickshell provee varios tipos para diferentes casos de uso:

### ShellRoot
La raiz del shell. Contiene todas las ventanas y gestiona el ciclo de vida.

```qml
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Panel {
        // Barra superior - se ancla a los bordes de la pantalla
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 44
        exclusiveZone: height  // Reserva espacio para que otras ventanas no se superpongan
    }
    
    Window {
        // Ventana flotante (launcher, popup)
        anchors.centerIn: parent
    }
}
```

### Panel
Ventana de tipo "layer shell" que se ancla a bordes. Ideal para barras.
- `exclusiveZone`: reserva espacio en el desktop.
- `anchors`: define posicion relativa a la pantalla.

### Window
Ventana normal que puede flotar sobre el desktop.
- No reserva espacio exclusivo.
- Se usa para popups, launchers, dialogs.

## 3.2 Modulos Quickshell.Io

### Process
Ejecuta comandos externos de forma asincrona.

```qml
import Quickshell.Io

Process {
    id: myProc
    command: ["echo", "hola"]
    
    stdout: SplitParser {
        onRead: (data) => console.log("STDOUT:", data)
    }
    
    stderr: SplitParser {
        onRead: (data) => console.error("STDERR:", data)
    }
    
    onExited: (exitCode) => {
        console.log("Proceso termino con codigo:", exitCode)
    }
}

// Ejecutar
Component.onCompleted: myProc.running = true
```

### FileView
Observa archivos y directorios para detectar cambios.

```qml
FileView {
    id: fileWatcher
    path: "/tmp/mi-archivo.txt"
    watchChanges: true  // Detecta cambios de contenido
    onFileChanged: console.log("Archivo modificado!")
}
```

### SocketConnector
Conecta a sockets UNIX para comunicacion en tiempo real.

```qml
import Quickshell.Io

SocketConnector {
    id: hyprlandSocket
    address: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket2.sock"
    
    onConnected: console.log("Conectado al socket de Hyprland")
    onDisconnected: console.log("Desconectado")
}
```

## 3.3 Variables de Entorno

Quickshell expone variables de entorno de forma segura:

```qml
Quickshell.env("HOME")           // /home/usuario
Quickshell.env("XDG_RUNTIME_DIR") // /run/user/1000
Quickshell.env("DISPLAY")        // (vacio en Wayland)
```

## 3.4 El patron de shell.qml del proyecto

El archivo `shell.qml` es el punto de entrada. Su estructura es:

```qml
ShellRoot {
    id: root
    
    // Propiedades globales
    property bool screenshotActive: false
    
    // Comandos globales (archivo de comando para IPC externo)
    readonly property string commandFilePath: ...
    
    // Los modulos se instancian aqui
    Bar { ... }
    OrbitAI { ... }
    // etc.
}
```

## Ejercicios

### Ejercicio 3.1: Panel basico
Crea un `shell.qml` minimal que muestre un Panel con un reloj.

### Ejercicio 3.2: Proceso con salida
Crea un componente que ejecute `uptime` y muestre el resultado.

### Ejercicio 3.3: Watcher de archivo
Crea un FileView que observe `data/state/state.json` y loguee cambios.

### Ejercicio 3.4: Analizar shell.qml
Lee el `shell.qml` del proyecto. Identifica:
- Que modulos se cargan
- Como se gestiona el archivo de comando externo
- Que propiedades globales se exponen
