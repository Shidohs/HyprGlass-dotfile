pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config

Item {
    id: root

    implicitWidth: Config.fontSizeIconSmall + 4
    implicitHeight: Config.fontSizeIconSmall + 4
    visible: BatteryService.hasBattery

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignVCenter

    // Propiedad para recibir color externo
    property color color: {
        if (BatteryService.isCharging) return Config.successColor;
        if (BatteryService.percentage <= 20) return Config.errorColor;
        return Config.textColor;
    }

    Text {
        id: iconText
        anchors.centerIn: parent
        font.family: Config.font
        font.pixelSize: Config.fontSizeIconSmall
        font.bold: true
        text: BatteryService.getBatteryIcon()
        color: root.color
    }

    /* 
    // Espacio reservado para tu SVG manual futuro:
    Image {
        anchors.fill: parent
        visible: false // cámbiame a true cuando tengas el SVG
        source: "tu-icon-aqui.svg"
    }
    */
}
