# Modulo 4: DBus Nativo - Reemplazar Scripts Bash

## Objetivos

- Entender DBus y su arquitectura.
- Conectar QML a servicios DBus nativamente.
- Reemplazar `bluetoothctl` y otros scripts con bindings directos.
- Mejorar la estabilidad eliminando procesos externos.

## 4.1 Que es DBus?

DBus es un sistema de comunicacion entre procesos (IPC) en Linux. Tiene dos buses:

| Bus | Uso |
|-----|-----|
| System Bus | Servicios del sistema (Bluez, NetworkManager, UPower) |
| Session Bus | Servicios del usuario (MPRIS, notificacions, etc.) |

### Conceptos clave

- **Service**: Un nombre como `org.bluez` o `org.freedesktop.NetworkManager`
- **Object Path**: Una ruta como `/org/bluez/hci0` o `/org/freedesktop/NetworkManager/AccessPoint/123`
- **Interface**: Un contrato como `org.freedesktop.DBus.Properties`
- **Property**: Un valor que se puede leer/escribir
- **Signal**: Un evento que se emite cuando algo cambia
- **Method**: Una funcion que se puede llamar remotamente

## 4.2 Problema actual: Scripts Bash

El proyecto actual usa `Process {}` para ejecutar comandos bash:

```qml
// WallpaperManagerService.qml - PROBLEMA
Process {
    id: _applyProc
    command: ["bash", scriptPath, "--file", path]
    onExited: (exitCode) => { ... }
}

// BluetoothService.qml - PROBLEMA
Process {
    id: powerProc
    command: ["bluetoothctl", "power", "off"]
}
```

**Problemas:**
1. Cada comando lanza un proceso nuevo (overhead).
2. Los procesos pueden fallar silenciosamente.
3. El parsing de salida de CLI es fragil.
4. No hay tipo de retorno seguro.
5. Los scripts externos crean dependencias ocultas.

## 4.3 Solucion: DBus Nativo en QML

Quickshell soporta DBus directamente. Puedes leer propiedades y llamar metodos sin procesos externos.

### Ejemplo: UPower (Bateria)

```qml
import Quickshell.Io

DBusProxy {
    id: upowerDevice
    bus: DBus.SystemBus
    service: "org.freedesktop.UPower"
    path: "/org/freedesktop/UPower/devices/DisplayDevice"
    iface: "org.freedesktop.UPower.Device"
    
    // Leer propiedades
    property real percentage: 0
    property bool charging: false
    
    Component.onCompleted: {
        // Leer valor inicial
        percentage = getProperty("Percentage")
        charging = getProperty("State") === 1  // 1 = charging
    }
    
    // Escuchar cambios
    onPropertiesChanged: (properties) => {
        if ("Percentage" in properties)
            percentage = properties["Percentage"]
        if ("State" in properties)
            charging = properties["State"] === 1
    }
}
```

### Ejemplo: Bluez (Bluetooth)

```qml
import Quickshell.Io

// Adapter
DBusProxy {
    id: btAdapter
    bus: DBus.SystemBus
    service: "org.bluez"
    path: "/org/bluez/hci0"
    iface: "org.bluez.Adapter1"
    
    property bool powered: false
    property bool discovering: false
    
    Component.onCompleted: {
        powered = getProperty("Powered")
        discovering = getProperty("Discovering")
    }
    
    function setPowered(state) {
        setProperty("Powered", state)
    }
    
    function startDiscovery() {
        callMethod("StartDiscovery")
    }
    
    function stopDiscovery() {
        callMethod("StopDiscovery")
    }
}
```

## 4.4 Servicio mejorado: BatteryService con DBus nativo

El servicio actual probablemente usa `Process {}` para leer bateria. Aqui una version mejorada:

```qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    property real percentage: 0
    property bool charging: false
    property real timeToFull: 0
    property real timeToEmpty: 0
    
    DBusProxy {
        id: upower
        bus: DBus.SystemBus
        service: "org.freedesktop.UPower"
        path: "/org/freedesktop/UPower/devices/DisplayDevice"
        iface: "org.freedesktop.DBus.Properties"
        
        Component.onCompleted: {
            refresh()
        }
        
        function refresh() {
            const props = getAllProperties()
            root.percentage = props["Percentage"] || 0
            const state = props["State"] || 0
            root.charging = state === 1
            root.timeToFull = props["TimeToFull"] || 0
            root.timeToEmpty = props["TimeToEmpty"] || 0
        }
    }
    
    // Escuchar cambios de propiedades
    DBusProxy {
        id: upowerSignals
        bus: DBus.SystemBus
        service: "org.freedesktop.UPower"
        path: "/org/freedesktop/UPower/devices/DisplayDevice"
        iface: "org.freedesktop.DBus.Properties"
        
        onPropertiesChanged: (changed, invalidated) => {
            if ("Percentage" in changed) root.percentage = changed["Percentage"]
            if ("State" in changed) root.charging = changed["State"] === 1
        }
    }
    
    readonly property string icon: {
        if (percentage >= 0.95) return "battery-level-100-symbolic"
        if (percentage >= 0.80) return "battery-level-80-symbolic"
        if (percentage >= 0.50) return "battery-level-50-symbolic"
        if (percentage >= 0.20) return "battery-level-20-symbolic"
        return "battery-level-0-symbolic"
    }
    
    readonly property string timeRemaining: {
        if (charging && timeToFull > 0)
            return Math.round(timeToFull / 60) + " min"
        if (!charging && timeToEmpty > 0)
            return Math.round(timeToEmpty / 60) + " min"
        return ""
    }
}
```

## Ejercicios

### Ejercicio 4.1: Explorar DBus
Ejecuta `dbus-send --system --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames` para ver servicios disponibles.

### Ejercicio 4.2: Leer bateria con DBus
Usa `dbus-send` para leer la bateria de UPower manualmente.

### Ejercicio 4.3: Reimplementar AudioService
El AudioService actual usa `Quickshell.Services.Pipewire` (correcto). Identifica otros servicios que usan `Process {}` y reescribelos con DBus.

### Ejercicio 4.4: Servicio de Red con DBus
Crea un `NetworkServiceNative.qml` que use `org.freedesktop.NetworkManager` directamente.
