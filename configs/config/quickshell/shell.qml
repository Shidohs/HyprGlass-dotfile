//@ pragma Env QS_NO_RELOAD_POPUP=1
pragma ComponentBehavior: Bound

// shell.qml — punto de entrada principal del shell.
//
// Módulos lazy-loaded (se activan por flags en sus servicios):

//   PowerService.overlayVisible               → PowerOverlay
//   LauncherService.visible                   → Launcher
//   OsdService.visible                        → OsdOverlay
//   WallpaperService.pickerVisible            → WallpaperPicker
//   ClipboardService.visible                  → ClipboardHistory
//   root.screenshotActive                     → ScreenshotManager
//   keybindsLoader.active (manual)            → KeybindsOverlay
//
// El agente Bluetooth (bluetooth-agent.py) se auto-reinicia si falla.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import "./modules/shell/bar/"
import "./modules/tools/orbit/"

ShellRoot {
    id: root

    // =========================================================================
    // GLOBAL MODULE STATE
    // =========================================================================

    property bool screenshotActive: false
    readonly property bool hyprlandGlobalShortcutsAvailable: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== ""
    readonly property string commandRuntimeDir: {
        const runtimeDir = Quickshell.env("XDG_RUNTIME_DIR");
        if (runtimeDir)
            return runtimeDir;
        return Quickshell.env("HOME") + "/.config/hypr/externals/quickshell/data/runtime";
    }
    readonly property string commandFilePath: commandRuntimeDir + "/quickshell-command"
    property string commandWatchPath: ""
    property string lastExternalCommandPayload: ""
    property bool commandReadPending: false
    readonly property bool debugLogging: false

    // ARCHITECTURE FIX: Limit bluetooth agent restart attempts
    property int bluetoothCrashCount: 0
    readonly property int maxBluetoothCrashes: 5

    function _queueCommandRead() {
        if (_readCommandFile.running) {
            commandReadPending = true;
            return;
        }
        _readCommandFile.running = true;
    }

    function _drainCommandRead() {
        Qt.callLater(() => {
            if (commandReadPending && !_readCommandFile.running) {
                commandReadPending = false;
                _readCommandFile.running = true;
            }
        });
    }

    Component.onCompleted: {
        _prepareCommandFile.running = true;
    }

    Process {
        id: _prepareCommandFile
        command: ["bash", "-lc", "mkdir -p \"$1\" && touch \"$2\"", "qs-cmd-init", root.commandRuntimeDir, root.commandFilePath]

        onExited: exitCode => {
            if (exitCode === 0) {
                root.commandWatchPath = root.commandFilePath;
                root._queueCommandRead();
            } else {
                console.error("[Shell] Failed to initialize command file:", root.commandFilePath);
            }
        }
    }

    FileView {
        id: commandWatcher
        path: root.commandWatchPath
        watchChanges: true
        onFileChanged: root._queueCommandRead()
    }

    Process {
        id: _readCommandFile
        command: ["cat", root.commandFilePath]
        property string _buf: ""

        stdout: SplitParser {
            onRead: data => _readCommandFile._buf += data
        }

        onStarted: _buf = ""

        onExited: exitCode => {
            if (exitCode !== 0) {
                _buf = "";
                root._drainCommandRead();
                return;
            }

            const lines = _buf.trim().split("\n");
            const payload = lines.length > 0 ? lines[lines.length - 1].trim() : "";
            _buf = "";
            if (!payload) {
                root._drainCommandRead();
                return;
            }

            if (payload === root.lastExternalCommandPayload) {
                root._drainCommandRead();
                return;
            }
            root.lastExternalCommandPayload = payload;

            const command = payload.split(" ")[0];

            switch (command) {
            case "wallpaper_picker":
                WallpaperService.show();
                break;
            case "app_launcher":
                LauncherService.show();
                break;
            case "clipboard_history":
                ClipboardService.toggle();
                break;
            case "keybinds_help":
                keybindsLoader.toggle();
                break;
            case "take_screenshot":
                root.screenshotActive = true;
                break;
            default:
                console.warn("[Shell] Unknown external command:", command);
            }

            root._drainCommandRead();
        }
    }

    // =========================================================================
    // BLUETOOTH AGENT
    // =========================================================================

    readonly property string bluetoothAgentScriptPath: Qt.resolvedUrl("./scripts/agents/bluetooth-agent.py").toString().replace("file://", "")

    Process {
        id: bluetoothAgent
        command: ["python3", root.bluetoothAgentScriptPath]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (root.debugLogging)
                    console.log("[BluetoothAgent]: " + data);
            }
        }
        stderr: SplitParser {
            onRead: data => console.error("[BluetoothAgent]: " + data)
        }

        // ARCHITECTURE FIX: Auto-restart with max retries to prevent infinite loop
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.bluetoothCrashCount++;

                if (root.bluetoothCrashCount >= root.maxBluetoothCrashes) {
                    console.error("[BluetoothAgent] Max crash limit reached (" + root.maxBluetoothCrashes + "), disabling auto-restart");
                    OsdService.showMessage("🔴", "Bluetooth agent disabled (too many crashes)");
                    return;
                }

                console.warn("[BluetoothAgent] Crash " + root.bluetoothCrashCount + "/" + root.maxBluetoothCrashes + ", exited with code " + exitCode + " — restarting in 3s");
                bluetoothAgentRestartTimer.restart();
            } else {
                // Successful exit, reset counter
                root.bluetoothCrashCount = 0;
            }
        }
    }

    Timer {
        id: bluetoothAgentRestartTimer
        interval: 3000
        repeat: false
        onTriggered: {
            console.log("[BluetoothAgent] Restarting (attempt " + (root.bluetoothCrashCount + 1) + ")...");
            bluetoothAgent.running = true;
        }
    }

    // =========================================================================
    // SWAYNC NOTIFICATION DAEMON
    // =========================================================================

    Process {
        id: swayncDaemon
        command: ["swaync"]
        running: true

        stderr: SplitParser {
            onRead: data => {
                if (root.debugLogging)
                    console.log("[SwayNC]: " + data);
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (root.debugLogging)
                console.log("[SwayNC] exited with code " + exitCode);
        }
    }

    // =========================================================================
    // UI COMPONENTS - LAZY LOADING
    // =========================================================================

    // Bar - always active (main component)
    Bar {}

    Loader {
        id: orbitLoader
        active: AiService.windowVisible
        source: "./modules/tools/orbit/OrbitChatWindow.qml"

        onStatusChanged: {
            if (root.debugLogging && status === Loader.Ready)
                console.log("[Shell] Orbit window loaded");
            else if (status === Loader.Error)
                console.error("[Shell] Error loading Orbit: " + source);
        }
    }



    // Power Overlay
    Loader {
        id: powerLoader
        active: PowerService.overlayVisible
        source: "./modules/shell/power/PowerOverlay.qml"

        onStatusChanged: {
            if (root.debugLogging && status === Loader.Ready)
                console.log("[Shell] PowerOverlay loaded");
        }
    }

    // Screenshot Manager
    Loader {
        id: screenshotLoader
        active: root.screenshotActive
        source: "./modules/appearance/screenshot/ScreenshotManager.qml"

        onStatusChanged: {
            if (status === Loader.Ready) {
                if (root.debugLogging)
                    console.log("[Shell] ScreenshotManager loaded");
                screenshotLoader.item.startCapture();
            }
        }

        // Deactivate when screenshot finishes
        Connections {
            target: screenshotLoader.item
            enabled: screenshotLoader.status === Loader.Ready

            function onActiveChanged() {
                if (screenshotLoader.item && !screenshotLoader.item.active) {
                    root.screenshotActive = false;
                }
            }
        }
    }

    // Launcher
    Loader {
        active: LauncherService.visible
        source: "./modules/shell/launcher/Launcher.qml"
    }

    // Quick Settings
    Loader {
        active: QuickSettingsService.visible
        source: "./modules/shell/quickSettings/QuickSettingsWindow.qml"

        onStatusChanged: {
            if (status === Loader.Ready && item)
                item.visible = true;
        }
    }

    // OSD
    Loader {
        active: OsdService.visible
        source: "./modules/shell/osd/OsdOverlay.qml"
    }

    // Wallpaper Picker
    Loader {
        active: WallpaperService.pickerVisible
        source: "./modules/appearance/wallpaper/WallpaperPicker.qml"
    }

    Loader {
        id: clipboardLoader
        active: ClipboardService.visible
        source: "./modules/tools/clipboard/ClipboardHistory.qml"
    }

    // Keybinds Overlay
    Loader {
        id: keybindsLoader
        active: false
        source: "./modules/shell/keybinds/KeybindsOverlay.qml"

        function toggle() {
            if (active && item) {
                item.hide();
                active = false;
            } else {
                active = true;
            }
        }

        Connections {
            target: keybindsLoader.item
            enabled: keybindsLoader.status === Loader.Ready

            function onShowingChanged() {
                if (keybindsLoader.item && !keybindsLoader.item.showing)
                    keybindsLoader.active = false;
            }
        }

        onStatusChanged: {
            if (status === Loader.Ready && item)
                item.showing = true;
        }
    }

    // =========================================================================
    // GLOBAL SHORTCUTS
    // =========================================================================

    Loader {
        id: hyprlandShortcutsLoader
        active: root.hyprlandGlobalShortcutsAvailable
        source: "./modules/shell/shortcuts/HyprlandGlobalShortcuts.qml"

        onLoaded: {
            if (item) {
                item.shellRoot = root;
                item.keybindsLoader = keybindsLoader;
            }
        }
    }

    Connections {
        target: ShortcutService

        function onScreenshotRequested() {
            root.screenshotActive = true;
        }

        function onPowerMenuRequested() {
            PowerService.showOverlay();
        }

        function onQuickSettingsRequested() {
            QuickSettingsService.show("dashboard");
        }

        function onClipboardRequested() {
            ClipboardService.show();
        }
    }
}
