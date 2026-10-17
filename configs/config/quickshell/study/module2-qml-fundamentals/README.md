# Modulo 2: QML y Qt Quick - Fundamentos

## Objetivos

- Crear componentes visuales basicos con QML.
- Entender el sistema de propiedades y bindings.
- Usar signals y slots para eventos.
- Crear componentes reutilizables.

## 2.1 Sintaxis declarativa

QML es un lenguaje declarativo basado en JavaScript. Describe **que** debe haber en pantalla, no **como** dibujarlo.

```qml
import QtQuick

Rectangle {
    width: 200
    height: 100
    color: "steelblue"
    
    Text {
        text: "Hola Mundo"
        anchors.centerIn: parent
        color: "white"
    }
}
```

## 2.2 Propiedades y Bindings

Las propiedades en QML son reactivas. Cuando cambias una, todo lo que depende de ella se actualiza automaticamente.

```qml
Rectangle {
    width: 200
    height: width / 2  // Binding: si width cambia, height se ajusta
    
    Text {
        id: label
        text: "Ancho: " + parent.width  // Binding automatico
    }
    
    Component.onCompleted: {
        // Esto cambia width, y height se ajusta solo
        width = 300
    }
}
```

### Binding vs Asignacion

```qml
// Binding (se mantiene conectado):
height: width / 2

// Asignacion (rompe el binding):
Component.onCompleted: height = 100  // Ya no sigue a width
```

## 2.3 Propiedades personalizadas

```qml
Item {
    property int count: 0
    property string nombre: "MiComponente"
    property color accentColor: "#7aa2f7"
    property bool isActive: true
    
    // Propiedad readonly (no se puede modificar desde fuera)
    readonly property string label: count + " elementos"
}
```

## 2.4 Signals y Slots

```qml
Item {
    signal clicked(int x, int y)
    signal valueChanged(real newValue)
    
    MouseArea {
        anchors.fill: parent
        onClicked: (mouse) => parent.clicked(mouse.x, mouse.y)
    }
    
    // Conectar signals
    Component.onCompleted: {
        clicked.connect(handleClick)
    }
    
    function handleClick(x, y) {
        console.log("Click en:", x, y)
    }
}
```

## 2.5 Componentes reutilizables

Crear un archivo `CustomButton.qml`:

```qml
import QtQuick

Rectangle {
    id: root
    
    // Propiedades publicas
    property string label: "Boton"
    property color normalColor: Config.accentColor
    property color hoverColor: Config.surface2Color
    
    width: 120
    height: 40
    radius: 8
    color: normalColor
    
    signal clicked()
    
    Text {
        text: root.label
        anchors.centerIn: parent
        color: "white"
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.color = root.hoverColor
        onExited: root.color = root.normalColor
        onClicked: root.clicked()
    }
}
```

Uso en otro archivo:

```qml
import QtQuick

Column {
    CustomButton {
        label: "Aceptar"
        onClicked: console.log("Aceptado")
    }
    
    CustomButton {
        label: "Cancelar"
        normalColor: Config.errorColor
        onClicked: console.log("Cancelado")
    }
}
```

## 2.6 El patron de Config.qml del proyecto

En `config/Config.qml` se centralizan todos los valores de personalizacion:

```qml
// Config.qml expone propiedades globales
readonly property color accentColor: ThemeService.color("accent", "#7aa2f7")
readonly property int radius: getState("geometry.radius", 10)
readonly property string font: "Caskaydia Cove Nerd Font"
```

Cualquier componente puede acceder: `Config.accentColor`, `Config.radius`, etc.

## Ejercicios

### Ejercicio 2.1: Tarjeta basica
Crea un componente `Card.qml` con fondo, borde redondeado y sombra. Debe aceptar propiedades `title` y `content`.

### Ejercicio 2.2: Slider personalizado
Crea un `CustomSlider.qml` que muestre un icono, una barra de progreso y un porcentaje. Debe emitir `valueChanged(real value)`.

### Ejercicio 2.3: Lista de items
Crea un componente `ItemList.qml` que reciba un array de objetos y los muestre como una lista de tarjetas.

### Ejercicio 2.4: Analizar componentes del proyecto
Lee los archivos en `components/base/` y `components/shell/`. Identifica:
- Que propiedades exponen
- Que signals emiten
- Como acceden a Config
