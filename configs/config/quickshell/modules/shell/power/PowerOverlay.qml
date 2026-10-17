pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
    id: root

    property bool visible: PowerService.overlayVisible
    property int selectedIndex: 0

    readonly property var actions: [
        {
            id: "shutdown",
            icon: "󰐥",
            color: Config.errorColor,
            label: "Shutdown"
        },
        {
            id: "reboot",
            icon: "󰜉",
            color: Config.warningColor,
            label: "Reboot"
        },
        {
            id: "suspend",
            icon: "󰒲",
            color: Config.accentColor,
            label: "Suspend"
        },
        {
            id: "logout",
            icon: "󰍃",
            color: Config.subtextColor,
            label: "Log Out"
        },
        {
            id: "lock",
            icon: "󰌾",
            color: Config.subtextColor,
            label: "Lock"
        }
    ]

    function navigate(delta) {
        selectedIndex = (selectedIndex + delta + actions.length) % actions.length;
    }

    function executeSelected() {
        PowerService.executeAction(actions[selectedIndex].id);
    }

    // 1) Full-screen dim layer
    PanelWindow {
        id: dimLayer
        visible: root.visible

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "qs_fullscreen"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: PowerService.hideOverlay()
        }
    }

    // 2) Popup layer
    PanelWindow {
        id: popupLayer
        visible: root.visible

        // Center on screen automatically handled by Niri or we can just size it
        implicitWidth: contentColumn.implicitWidth + 48
        implicitHeight: contentColumn.implicitHeight + 40

        WlrLayershell.namespace: "qs_popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        color: "transparent"
        mask: Region {
            item: powerWidget
        }

        // Central widget
        Rectangle {
            id: powerWidget

            anchors.fill: parent

            radius: Config.radiusLarge
            color: Config.moduleBackgroundColor
            border.width: 1
            border.color: Config.surface2Color

            scale: root.visible ? 1.0 : 0.9
            opacity: root.visible ? 1.0 : 0.0

            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            ColumnLayout {
                id: contentColumn
                anchors.centerIn: parent
                spacing: 20

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "What would you like to do?"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeLarge
                    font.weight: Font.DemiBold
                    color: Config.textColor
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Repeater {
                        model: root.actions

                        delegate: Rectangle {
                            id: actionBtn

                            required property var modelData
                            required property int index

                            Layout.preferredWidth: 72
                            Layout.preferredHeight: 80

                            radius: Config.radius

                            property bool isSelected: index === root.selectedIndex

                            color: {
                                if (isSelected)
                                    return Config.surface1Color;
                                if (btnMouse.containsMouse)
                                    return Config.surface0Color;
                                return "transparent";
                            }

                            border.width: isSelected ? 2 : 0
                            border.color: modelData.color

                            scale: btnMouse.pressed ? 0.95 : 1.0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 80
                                }
                            }
                            Behavior on border.width {
                                NumberAnimation {
                                    duration: 100
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 44
                                    radius: 22
                                    color: actionBtn.isSelected ? Qt.alpha(actionBtn.modelData.color, 0.2) : Config.surface0Color

                                    Text {
                                        anchors.centerIn: parent
                                        text: actionBtn.modelData.icon
                                        font.family: Config.font
                                        font.pixelSize: 22
                                        color: actionBtn.isSelected || btnMouse.containsMouse ? actionBtn.modelData.color : Config.textColor
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: actionBtn.modelData.label
                                    font.family: Config.font
                                    font.pixelSize: Config.fontSizeSmall
                                    color: actionBtn.isSelected ? Config.textColor : Config.subtextColor
                                }
                            }

                            Rectangle {
                                visible: actionBtn.isSelected
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 4
                                width: 18
                                height: 18
                                radius: 4
                                color: Config.surface2Color

                                Text {
                                    anchors.centerIn: parent
                                    text: String(actionBtn.index + 1)
                                    font.family: Config.font
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Config.subtextColor
                                }
                            }

                            MouseArea {
                                id: btnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (actionBtn.isSelected) {
                                        root.executeSelected();
                                    } else {
                                        root.selectedIndex = actionBtn.index;
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    Repeater {
                        model: [
                            {
                                key: "←→",
                                label: "Navigate"
                            },
                            {
                                key: "Enter",
                                label: "Confirm"
                            },
                            {
                                key: "Esc",
                                label: "Cancelar"
                            }
                        ]

                        Row {
                            required property var modelData
                            spacing: 4

                            Rectangle {
                                width: keyText.implicitWidth + 8
                                height: 18
                                radius: 4
                                color: Config.surface1Color
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: keyText
                                    anchors.centerIn: parent
                                    text: modelData.key
                                    font.family: Config.font
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Config.subtextColor
                                }
                            }

                            Text {
                                text: modelData.label
                                font.family: Config.font
                                font.pixelSize: 10
                                color: Config.mutedColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // Keyboard
            Item {
                id: keyHandler
                focus: true

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        PowerService.hideOverlay();
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.executeSelected();
                        break;
                    case Qt.Key_Left:
                    case Qt.Key_H:
                        root.navigate(-1);
                        break;
                    case Qt.Key_Right:
                    case Qt.Key_L:
                        root.navigate(1);
                        break;
                    case Qt.Key_1:
                    case Qt.Key_2:
                    case Qt.Key_3:
                    case Qt.Key_4:
                    case Qt.Key_5:
                        root.selectedIndex = event.key - Qt.Key_1;
                        root.executeSelected();
                        break;
                    }
                    event.accepted = true;
                }
            }

            Timer {
                id: focusTimer
                interval: 50
                onTriggered: {
                    keyHandler.forceActiveFocus();
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0;
            focusTimer.restart();
        }
    }
}
