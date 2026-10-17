pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.components

BarButton {
    id: root

    property int notifCount: 0
    property bool dndActive: false

    contentItem: iconRow

    onClicked: _togglePanel.running = true
    onRightClicked: _toggleDnd.running = true

    Row {
        id: iconRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            text: root.dndActive ? "󰂛" : "󰂚"
            font.family: Config.font
            font.pixelSize: Config.fontSizeIcon
            color: root.hovered ? Config.accentColor : Config.textColor

            Behavior on color {
                ColorAnimation { duration: Config.animDuration }
            }
        }

        Rectangle {
            visible: root.notifCount > 0 && !root.dndActive
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(badgeText.implicitWidth + 8, height)
            height: 16
            radius: 8
            color: Config.accentColor

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: root.notifCount > 99 ? "99+" : root.notifCount
                font.family: Config.font
                font.pixelSize: 10
                font.bold: true
                color: Config.textReverseColor
            }
        }
    }

    // ── NATIVE EVENT SUBSCRIPTION (NO POLLING) ──
    Process {
        id: _subscriber
        command: ["swaync-client", "-swb"] // -swb outputs JSON streams continuously
        running: true // Stays running forever

        stdout: SplitParser {
            onRead: data => {
                if (!data) return;
                try {
                    const status = JSON.parse(data);
                    if (status.text !== undefined) {
                        root.notifCount = parseInt(status.text) || 0;
                    }
                    if (status.alt !== undefined) {
                        root.dndActive = status.alt.includes("dnd") || status.alt === "dnd";
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: _togglePanel
        command: ["swaync-client", "-t", "-sw"]
    }

    Process {
        id: _toggleDnd
        command: ["swaync-client", "-d", "-sw"]
    }
}
