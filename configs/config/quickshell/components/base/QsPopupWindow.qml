pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: root

    property int popupWidth: 380
    property int popupMaxHeight: 700
    property string anchorSide: "left"
    property string moduleName: ""
    property string layerNamespace: "qs_modules"
    property real contentImplicitHeight: 0
    property real backgroundOpacity: Config.moduleOpacity
    property var focusTarget: background

    default property alias content: contentContainer.data

    signal closing

    readonly property int screenMargin: 0
    readonly property real popupHeight: Math.min(popupMaxHeight, contentImplicitHeight + 32)

    WlrLayershell.namespace: layerNamespace
    WlrLayershell.layer: WlrLayer.Overlay
    // Some windows don't need keyboard focus, avoid Wayland focus-stealing issues
    property int keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.keyboardFocus: keyboardFocus
    WlrLayershell.exclusiveZone: -1

    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: anchorSide === "left"
        right: anchorSide === "right"
    }

    margins {
        top: Config.barHeight + 10
        left: anchorSide === "left" ? 10 : 0
        right: anchorSide === "right" ? 10 : 0
    }

    implicitWidth: popupWidth
    implicitHeight: popupHeight
    color: "transparent"

    mask: Region {
        item: background
    }

    property bool isClosing: false
    property bool isOpening: false

    function closeWindow() {
        if (!visible)
            return;
        isClosing = true;
        root.closing();
        root.visible = false;
        root.isClosing = false;
    }

    property bool closeOnFocusLost: true

    Timer {
        id: grabTimer
        interval: 10
        onTriggered: {
            const target = root.focusTarget || background;
            if (target)
                target.forceActiveFocus();
        }
    }

    onVisibleChanged: {
        if (visible) {
            isClosing = false;
            isOpening = true;
            if (moduleName !== "")
                WindowManagerService.registerOpen(moduleName);
            grabTimer.restart();
        } else {
            isOpening = false;
            if (moduleName !== "")
                WindowManagerService.registerClose(moduleName);
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: background
            width: root.popupWidth
            height: root.popupHeight
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.screenMargin
            color: Qt.alpha(Config.backgroundColor, root.backgroundOpacity)
            radius: Config.radiusLarge
            border.width: 1.0
            border.color: Config.surface2Color
            clip: true

            transformOrigin: root.anchorSide === "left" ? Item.TopLeft : Item.TopRight

            property bool showState: visible && !root.isClosing && root.isOpening

            scale: showState ? 1.0 : 0.9
            opacity: showState ? 1.0 : 0.0

            Behavior on scale {
                NumberAnimation {
                    duration: Config.animDurationLong
                    easing.type: Easing.OutExpo
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animDurationShort
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuad
                }
            }

            Keys.onEscapePressed: root.closeWindow()

            Item {
                id: contentContainer
                anchors.fill: parent
                anchors.margins: 16
            }
        }
    }
}
