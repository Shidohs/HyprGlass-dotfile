import QtQuick
import Quickshell

// Legacy standalone entrypoint kept for compatibility.
// Delegate capture behavior to the migrated ScreenshotManager.
ScreenshotManager {
    Component.onCompleted: startCapture()
}
