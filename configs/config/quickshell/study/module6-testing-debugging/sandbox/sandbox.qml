pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 1280
    height: 800
    title: "Quickshell Sandbox"
    color: "#1e1e2e"

    QtObject {
        id: mockConfig
        readonly property color backgroundColor: "#1e1e2e"
        readonly property color surface0Color: "#313244"
        readonly property color surface1Color: "#45475a"
        readonly property color surface2Color: "#585b70"
        readonly property color accentColor: "#7aa2f7"
        readonly property color successColor: "#a6e3a1"
        readonly property color warningColor: "#f9e2af"
        readonly property color errorColor: "#f38ba8"
        readonly property color textColor: "#cdd6f4"
        readonly property color subtextColor: "#a6adc8"
        readonly property int radius: 10
        readonly property int radiusSmall: 5
        readonly property int padding: 6
        readonly property string font: "Caskaydia Cove Nerd Font"
        readonly property int fontSizeNormal: 14
        readonly property int fontSizeIcon: 22
    }

    QtObject {
        id: mockAudio
        property real volume: 0.65
        property bool muted: false
        readonly property string iconSource: muted ? "audio-volume-muted-symbolic" : "audio-volume-medium-symbolic"
        function setVolume(v) { volume = Math.max(0, Math.min(1, v)) }
        function toggleMute() { muted = !muted }
    }

    QtObject {
        id: mockBattery
        property real percentage: 0.78
        property bool charging: false
        property real timeToEmpty: 240
        readonly property string icon: percentage > 0.8 ? "battery-level-100-symbolic" : "battery-level-80-symbolic"
    }

    QtObject {
        id: mockBluetooth
        property bool powered: true
        property bool discovering: false
        property int scanTimeRemaining: 0
        readonly property var devicesList: [
            { name: "AirPods Pro", connected: true, icon: "headphone" },
            { name: "MX Master 3", connected: false, icon: "mouse", paired: true },
            { name: "iPhone de Juan", connected: false, icon: "phone", paired: true }
        ]
    }

    QtObject {
        id: mockNetwork
        property string ssid: "MiWiFi_5G"
        property int strength: 85
        property bool connected: true
        readonly property string icon: connected ? "network-wireless-signal-good-symbolic" : "network-wireless-disabled-symbolic"
    }

    Column {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 30

        Text {
            text: "Quickshell Sandbox"
            font.pixelSize: 24
            font.bold: true
            color: root.mockConfig.textColor
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Mock services disponibles: mockAudio, mockBattery, mockBluetooth, mockNetwork, mockConfig"
            font.pixelSize: 12
            color: root.mockConfig.subtextColor
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: parent.width - 80
            height: 1
            color: root.mockConfig.surface1Color
        }

        Grid {
            width: parent.width - 80
            columns: 2
            spacing: 20

            Rectangle {
                width: 280
                height: 120
                radius: root.mockConfig.radius
                color: root.mockConfig.surface0Color

                Column {
                    anchors.fill: parent
                    anchors.margins: root.mockConfig.padding
                    spacing: 8

                    Text {
                        text: "Audio Service"
                        font.pixelSize: 16
                        font.bold: true
                        color: root.mockConfig.textColor
                    }

                    Text {
                        text: "Volumen: " + Math.round(mockAudio.volume * 100) + "%"
                        color: root.mockConfig.subtextColor
                    }

                    Text {
                        text: "Muted: " + mockAudio.muted
                        color: root.mockConfig.subtextColor
                    }

                    Row {
                        spacing: 8
                        Rectangle {
                            width: 60
                            height: 28
                            radius: 6
                            color: root.mockConfig.accentColor
                            Text {
                                anchors.centerIn: parent
                                text: "Toggle"
                                color: "#1e1e2e"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: mockAudio.toggleMute()
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: 280
                height: 120
                radius: root.mockConfig.radius
                color: root.mockConfig.surface0Color

                Column {
                    anchors.fill: parent
                    anchors.margins: root.mockConfig.padding
                    spacing: 8

                    Text {
                        text: "Battery Service"
                        font.pixelSize: 16
                        font.bold: true
                        color: root.mockConfig.textColor
                    }

                    Text {
                        text: "Nivel: " + Math.round(mockBattery.percentage * 100) + "%"
                        color: root.mockConfig.subtextColor
                    }

                    Text {
                        text: "Cargando: " + mockBattery.charging
                        color: root.mockConfig.subtextColor
                    }

                    Rectangle {
                        width: 200
                        height: 12
                        radius: 6
                        color: root.mockConfig.surface1Color

                        Rectangle {
                            width: parent.width * mockBattery.percentage
                            height: parent.height
                            radius: parent.radius
                            color: mockBattery.charging ? root.mockConfig.successColor : root.mockConfig.accentColor
                        }
                    }
                }
            }
        }

        Item { width: 1; height: 20 }

        Text {
            text: "Para probar componentes del proyecto, importalos aqui y conectalos a los mock services."
            font.pixelSize: 12
            font.italic: true
            color: root.mockConfig.subtextColor
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
