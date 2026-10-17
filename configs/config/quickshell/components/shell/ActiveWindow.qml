pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config

Item {
    id: root

    property int maxWidth: 400
    property string windowTitle: ""
    readonly property bool windowExists: windowTitle !== ""
    readonly property bool niriSessionAvailable: (Quickshell.env("NIRI_SOCKET") || "") !== ""
    readonly property bool hyprlandSessionAvailable: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== ""
    readonly property string compositorBackend: niriSessionAvailable ? "niri" : (hyprlandSessionAvailable ? "hyprland" : "")

    function sanitizeWindowTitle(title) {
        return (title || "")
            .replace(/[\u0000-\u001f\u007f]+/g, " ")
            .replace(/\s+/g, " ")
            .trim();
    }

    function syncWindowTitle(title) {
        const nextTitle = sanitizeWindowTitle(title);
        if (windowTitle !== nextTitle)
            windowTitle = nextTitle;
    }

    function refreshFocusedWindow() {
        if (root.compositorBackend !== "" && !_focusedWindowProc.running)
            _focusedWindowProc.running = true;
    }

    Component.onCompleted: {
        refreshFocusedWindow();
    }

    implicitWidth: windowExists ? Math.min(titleText.implicitWidth + (Config.padding * 2), maxWidth) : 0
    implicitHeight: content.implicitHeight

    visible: opacity > 0
    opacity: windowExists ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: Config.animDuration
        }
    }
    Timer {
        id: titleSyncTimer
        interval: 450
        running: true
        repeat: true
        onTriggered: root.refreshFocusedWindow()
    }

    Process {
        id: _focusedWindowProc
        command: root.compositorBackend === "niri" ? ["niri", "msg", "-j", "focused-window"]
            : root.compositorBackend === "hyprland" ? ["hyprctl", "activewindow", "-j"]
            : []
        property string _buf: ""

        stdout: SplitParser {
            onRead: data => _focusedWindowProc._buf += data
        }

        onStarted: _buf = ""

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.syncWindowTitle("");
                _buf = "";
                return;
            }

            try {
                const data = JSON.parse(_buf.trim());
                root.syncWindowTitle(data?.title || data?.window?.title || "");
            } catch (e) {
                root.syncWindowTitle("");
            }

            _buf = "";
        }
    }

    Rectangle {
        id: content
        anchors.fill: parent
        implicitHeight: titleText.implicitHeight + (Config.padding * 1.2)
        radius: Config.radius
        clip: true
        color: Qt.alpha(Config.surface2Color, 0.7)
        border.width: 1
        border.color: Qt.alpha(Config.textColor, 0.12)

        Text {
            id: titleText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Config.padding
            anchors.rightMargin: Config.padding
            anchors.verticalCenter: parent.verticalCenter
            text: root.windowTitle !== "" ? "  " + root.windowTitle : ""
            color: Config.textColor
            font.family: Config.font
            font.pixelSize: Config.fontSizeLarge
            font.bold: true
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }
    }
}
