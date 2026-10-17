pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config

Item {
    id: root

    property color color: Config.textColor
    property bool isInput: false

    implicitWidth: Config.fontSizeIconSmall + 4
    implicitHeight: Config.fontSizeIconSmall + 4

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignVCenter

    Text {
        anchors.centerIn: parent
        font.family: Config.font
        font.pixelSize: Config.fontSizeIconSmall
        text: root.isInput ? AudioService.sourceIcon : AudioService.systemIcon
        color: root.color
    }
}
