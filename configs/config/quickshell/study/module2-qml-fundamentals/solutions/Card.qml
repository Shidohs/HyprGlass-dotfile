import QtQuick

Item {
    id: root
    width: 300
    height: 80

    property string title: "Tarjeta"
    property string content: "Contenido de ejemplo"
    property color bgColor: "#1e1e2e"
    property color borderColor: "#7aa2f7"
    property int borderWidth: 2

    signal clicked()

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.bgColor
        border.color: root.borderColor
        border.width: root.borderWidth

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: "transparent"
            border.color: "white"
            border.width: 1
            opacity: 0.1
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Text {
                text: root.title
                font.pixelSize: 18
                font.bold: true
                color: "#cdd6f4"
            }

            Text {
                text: root.content
                font.pixelSize: 14
                color: "#a6adc8"
                wrapMode: Text.WordWrap
                width: root.width - 32
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
