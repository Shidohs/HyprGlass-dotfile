import QtQuick

Rectangle {
    id: root
    width: 250
    height: 36
    radius: 6
    color: "#1e1e2e"

    property string icon: "󰕾"
    property real value: 0.5
    property string label: Math.round(value * 100) + "%"

    signal valueChanged(real newValue)

    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Text {
            text: root.icon
            font.pixelSize: 16
            verticalAlignment: Text.AlignVCenter
            width: 20
        }

        Rectangle {
            width: parent.width - 60
            height: 8
            radius: 4
            color: "#313244"

            Rectangle {
                width: parent.width * root.value
                height: parent.height
                radius: parent.radius
                color: "#7aa2f7"
            }
        }

        Text {
            text: root.label
            font.pixelSize: 12
            color: "#cdd6f4"
            verticalAlignment: Text.AlignVCenter
            width: 30
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => {
            const newValue = Math.max(0, Math.min(1, mouse.x / (root.width - 16)))
            root.value = newValue
            root.valueChanged(newValue)
        }
        onPositionChanged: (mouse) => {
            const newValue = Math.max(0, Math.min(1, mouse.x / (root.width - 16)))
            root.value = newValue
            root.valueChanged(newValue)
        }
    }
}
