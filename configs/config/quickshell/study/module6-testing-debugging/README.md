# Modulo 6: Testing, Debugging y Sandboxing

## Objetivos

- Usar qmllint para analisis estatico.
- Crear un entorno sandbox para probar componentes sin Hyprland.
- Implementar pruebas de componentes aislados.
- Depurar problemas comunes de QML/Quickshell.

## 6.1 qmllint - Analisis estatico

Quickshell incluye `qmllint` para verificar codigo QML antes de ejecutarlo:

```bash
# Verificar un archivo
qmllint shell.qml

# Verificar todo el proyecto
find . -name "*.qml" -exec qmllint {} +

# Verificar con output json (para CI)
qmllint --output-format json shell.qml
```

### Errores comunes que detecta:

| Error | Causa | Solucion |
|-------|-------|----------|
| `Unknown property` | Propiedad no definida | Declarar con `property type name` |
| `Type mismatch` | Tipo incorrecto | Usar el tipo correcto |
| `Signal not found` | Signal inexistente | Verificar nombre y parametros |
| `Deprecated API` | API antigua | Actualizar a la version nueva |

## 6.2 Sandbox de componentes

Crear un `sandbox.qml` que permite probar componentes sin necesitar Hyprland:

```qml
import QtQuick
import QtQuick.Window

Window {
    visible: true
    width: 1280
    height: 800
    title: "Quickshell Sandbox"
    color: "#1e1e2e"
    
    // Mock services para testing
    QtObject {
        id: mockAudio
        property real volume: 0.5
        property bool muted: false
        readonly property string iconSource: "audio-volume-medium-symbolic"
        
        function setVolume(v) { volume = Math.max(0, Math.min(1, v)) }
        function toggleMute() { muted = !muted }
    }
    
    QtObject {
        id: mockBattery
        property real percentage: 0.75
        property bool charging: true
        readonly property string icon: "battery-level-80-symbolic"
    }
    
    // Contenedor de prueba
    Column {
        anchors.centerIn: parent
        spacing: 20
        
        Text {
            text: "Sandbox - Prueba componentes aqui"
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#cdd6f4"
            font.pixelSize: 20
        }
        
        // Aqui importas tus componentes
        // ../components/base/VolumeSlider {
        //     value: mockAudio.volume
        //     muted: mockAudio.muted
        //     onVolumeChanged: mockAudio.setVolume(value)
        // }
    }
}
```

### Ejecutar sandbox:

```bash
# Ejecutar con Qt en modo standalone
quickshell sandbox.qml

# O con Qt directamente si tienes qml instalado
QT_QUICK_CONTROLS_STYLE=Basic qmlscene sandbox.qml
```

## 6.3 Debugging de QML

### console.log y debug
```qml
Component.onCompleted: {
    console.log("Componente creado:", objectName)
    console.debug("Valor de x:", x)
    console.warn("Advertencia:", someCondition)
    console.error("Error:", errorMessage)
}
```

### Inspector visual
Quickshell tiene herramientas de debug para ver la jerarquia de componentes:

```qml
// Activar debug en shell.qml
property bool debugMode: true

Component.onCompleted: {
    if (debugMode) {
        // Imprimir jerarquia
        dumpObjectTree()
    }
}
```

### Problemas comunes y soluciones:

| Problema | Causa probable | Solucion |
|----------|---------------|----------|
| UI no reacciona | Binding roto | Verificar que la propiedad existe |
| Crash al inicio | Import faltante | Agregar `import` necesario |
| Proceso zombie | Process sin cleanup | Usar `onExited` correctamente |
| Latencia alta | Operacion bloqueante | Mover a hilo secundario |
| Memoria creciente | Objetos no liberados | Usar `Component.onCompleted` correctamente |

## 6.4 Entorno de pruebas con Cage

[Cage](https://github.com/Hjdskes/cage) es un compositor Wayland minimal que permite ejecutar una sola aplicacion:

```bash
# Instalar cage
sudo pacman -S cage  # Arch
sudo apt install cage  # Debian

# Ejecutar sandbox en cage
cage -- quickshell sandbox.qml
```

## Ejercicios

### Ejercicio 6.1: Ejecutar qmllint
Ejecuta `qmllint` sobre todos los archivos QML del proyecto. Documenta los errores encontrados.

### Ejercicio 6.2: Crear sandbox
Copia el `sandbox.qml` proporcionado y agrega 2 componentes del proyecto para probarlos aislados.

### Ejercicio 6.3: Probar en Cage
Ejecuta el sandbox dentro de `cage` para verificar que funciona sin Hyprland.

### Ejercicio 6.4: Crear script de CI
Escribe un script `.github/workflows/qmllint.yml` que ejecute `qmllint` en cada PR.
