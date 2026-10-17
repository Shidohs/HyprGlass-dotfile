pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config

Item {
    id: root

    property color color: Config.textColor

    implicitWidth: Config.fontSizeIconSmall + 4
    implicitHeight: Config.fontSizeIconSmall + 4

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignVCenter

    Text {
        anchors.centerIn: parent
        font.family: Config.font
        font.pixelSize: Config.fontSizeIconSmall
        text: BluetoothService.systemIcon
        color: root.color
    }
}
