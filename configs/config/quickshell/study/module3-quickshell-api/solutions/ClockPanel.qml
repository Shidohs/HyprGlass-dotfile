pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

# Ejercicio 3.1 - Solucion: Panel basico con reloj
ShellRoot {
    id: root

    Panel {
        output: Quickshell.outputAt(0)
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 36
        exclusiveZone: height

        Rectangle {
            anchors.fill: parent
            color: "#1e1e2e"

            Row {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: {
                        const now = new Date()
                        return now.toLocaleTimeString(Qt.locale("es_ES"), Locale.ShortFormat)
                    }
                    color: "#cdd6f4"
                    font.pixelSize: 14
                    font.family: "Caskaydia Cove Nerd Font"

                    Timer {
                        interval: 1000
                        repeat: true
                        running: true
                        onTriggered: parent.text = new Date().toLocaleTimeString(Qt.locale("es_ES"), Locale.ShortFormat)
                    }
                }
            }
        }
    }
}
