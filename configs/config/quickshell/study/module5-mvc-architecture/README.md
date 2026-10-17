# Modulo 5: Arquitectura MVC y Gestion de Estado

## Objetivos

- Separar logica de negocio de la capa visual (MVC).
- Implementar gestion de estado centralizado con Singletons.
- Persistir estado en JSON sin bloquear la UI.
- Inyectar dependencias correctamente.

## 5.1 El problema del estado actual

El proyecto actual tiene varios problemas de arquitectura:

```
PROBLEMA: Estado disperso en multiples lugares
- shell.qml tiene bluetoothCrashCount, commandReadPending, etc.
- StateService lee de data/state/state.json
- WallpaperManagerService tiene su propio estado local
- ThemeService tiene su propio estado
- Los componentes leen directamente de servicios
```

**Consecuencias:**
- Dificil rastrear de donde viene un dato.
- Cambios en un lugar rompen otro.
- Imposible testear componentes aislados.
- Estado redundante (mismo dato en 3 lugares).

## 5.2 Patron MVC en QML

### Model (Datos/Servicios)
Los Singletons en `services/` son el Model. Deben:
- Contener TODA la logica de negocio.
- NO saber nada de la UI.
- Exponer propiedades limpias y senales.

```qml
// services/AudioModel.qml - Model puro
pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

Singleton {
    id: root
    
    // Estado
    readonly property real volume: sink ? sink.audio.volume : 0
    readonly property bool muted: sink ? sink.audio.muted : false
    readonly property var sink: Pipewire.defaultAudioSink
    
    // Acciones (no tocan la UI)
    function setVolume(v) {
        if (sink) sink.audio.volume = Math.max(0, Math.min(1, v))
    }
    
    function toggleMute() {
        if (sink) sink.audio.muted = !sink.audio.muted
    }
}
```

### View (Componentes visuales)
Los componentes en `components/` son la View. Deben:
- NO contener logica de negocio.
- Recibir datos como propiedades.
- Emitir senales para acciones.

```qml
// components/AudioSlider.qml - View pura
import QtQuick

Rectangle {
    id: root
    width: 200
    height: 40
    
    // Props de entrada (el model se inyecta desde arriba)
    property real value: 0
    property bool muted: false
    property string icon: ""
    
    // Senales de salida (no ejecutan logica)
    signal volumeRequested(real newVolume)
    signal muteToggleRequested()
    
    Text { text: root.icon }
    
    MouseArea {
        onClicked: root.muteToggleRequested()
    }
}
```

### Controller (Modulos que unen)
Los modulos en `modules/` son el Controller. Unen Model y View:

```qml
// modules/AudioModule.qml - Controller
import QtQuick
import qs.services

Row {
    AudioSlider {
        value: AudioModel.volume
        muted: AudioModel.muted
        icon: AudioModel.iconSource
        
        onVolumeRequested: (v) => AudioModel.setVolume(v)
        onMuteToggleRequested: AudioModel.toggleMute()
    }
}
```

## 5.3 StateService mejorado

El StateService actual lee JSON de archivo. Se puede mejorar con:
- Carga asincrona al inicio.
- Escritura en cola (debounce).
- Fallback a defaults si el archivo no existe.

```qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    readonly property string statePath: Quickshell.env("HOME") + "/.config/quickshell/data/state/state.json"
    property var _cache: ({})
    property bool loaded: false
    
    signal stateChanged()
    
    // Carga inicial
    Component.onCompleted: {
        loadState()
    }
    
    // Leer valor con fallback
    function get(path, fallback) {
        const keys = path.split(".")
        let obj = root._cache
        for (let key of keys) {
            if (obj && key in obj) {
                obj = obj[key]
            } else {
                return fallback
            }
        }
        return obj
    }
    
    // Escribir valor
    function set(path, value) {
        const keys = path.split(".")
        let obj = root._cache
        for (let i = 0; i < keys.length - 1; i++) {
            if (!(keys[i] in obj)) obj[keys[i]] = {}
            obj = obj[keys[i]]
        }
        obj[keys[keys.length - 1]] = value
        root.stateChanged()
        _saveDebounced()
    }
    
    Process {
        id: loadProc
        command: ["cat", root.statePath]
        
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    root._cache = JSON.parse(data)
                    root.loaded = true
                } catch(e) {
                    root._cache = {}
                    root.loaded = true
                }
            }
        }
    }
    
    // Debounce para escritura
    Timer {
        id: saveDebounce
        interval: 150
        onTriggered: {
            saveProc.command = ["bash", "-c", 'echo \'' + JSON.stringify(root._cache) + '\' > "' + root.statePath + '"']
            saveProc.running = true
        }
    }
    
    function _saveDebounced() {
        saveDebounce.restart()
    }
    
    function loadState() {
        loadProc.running = true
    }
}
```

## 5.4 Inyeccion de dependencias

En lugar de que cada componente importe servicios directamente, pasa los datos desde arriba:

```qml
// MAL: Componente acoplado al servicio
// components/VolumeControl.qml
import qs.services

MouseArea {
    onClicked: AudioService.toggleMute()  // Acoplado!
}

// BIEN: Componente recibe props
// components/VolumeControl.qml
MouseArea {
    property bool isMuted: false
    signal muteRequested()
    
    onClicked: muteRequested()  // Desacoplado!
}

// En el modulo:
VolumeControl {
    isMuted: AudioService.muted
    onMuteRequested: AudioService.toggleMute()
}
```

## Ejercicios

### Ejercicio 5.1: Refactorizar un componente
Toma un componente de `components/shell/` y separa la logica de la vista.

### Ejercicio 5.2: Crear un Store generico
Implementa un `JsonStore.qml` que pueda leer/escribir cualquier archivo JSON de forma asincrona.

### Ejercicio 5.3: Analizar acoplamiento
Busca en `modules/` componentes que importan directamente `qs.services`. Identifica cuantos podrian desacoplarse.

### Ejercicio 5.4: Crear un modulo MVC completo
Implementa un modulo de control de brillo con Model, View y Controller separados.
