pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "." as ScreenshotParts

Scope {
    id: root

    readonly property bool niriSessionAvailable: (Quickshell.env("NIRI_SOCKET") || "") !== ""
    readonly property bool hyprlandSessionAvailable: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== ""
    readonly property string compositorBackend: niriSessionAvailable ? "niri" : (hyprlandSessionAvailable ? "hyprland" : "")

    // =========================================================================
    // STATE
    // =========================================================================

    property bool active: false
    property string mode: "region"  // "region", "window", "screen"
    property bool editMode: false
    property string captureTimestamp: ""

    // Selection coordinates
    property real selectionX: 0
    property real selectionY: 0
    property real selectionWidth: 0
    property real selectionHeight: 0

    // Confirmation state
    property bool hasSelection: false

    // Window info
    property string selectedWindowTitle: ""
    property string selectedWindowClass: ""

    // Monitor tracking
    property var activeMonitorInfo: null
    property var activeScreen: null

    // IPC data (fresh on each capture)
    property var windowsFromIpc: []
    property var monitorsFromIpc: []

    readonly property var modes: ["region", "window", "screen"]
    readonly property var modeIcons: ({
            region: "󰩭",
            window: "󰖯",
            screen: "󰍹"
        })

    // =========================================================================
    // ANIMATIONS
    // =========================================================================

    Behavior on selectionX {
        enabled: Config.screenshotAnimations
        SpringAnimation {
            spring: 4
            damping: 0.4
        }
    }
    Behavior on selectionY {
        enabled: Config.screenshotAnimations
        SpringAnimation {
            spring: 4
            damping: 0.4
        }
    }
    Behavior on selectionWidth {
        enabled: Config.screenshotAnimations
        SpringAnimation {
            spring: 4
            damping: 0.4
        }
    }
    Behavior on selectionHeight {
        enabled: Config.screenshotAnimations
        SpringAnimation {
            spring: 4
            damping: 0.4
        }
    }

    // =========================================================================
    // IPC PROCESSES
    // =========================================================================

    Process {
        id: hyprctlMonitors
        command: root.compositorBackend === "niri" ? ["niri", "msg", "-j", "outputs"]
            : root.compositorBackend === "hyprland" ? ["hyprctl", "monitors", "-j"]
            : []
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const parsed = JSON.parse(data);
                    if (Array.isArray(parsed))
                        root.monitorsFromIpc = parsed;
                    else if (parsed && Array.isArray(parsed.outputs))
                        root.monitorsFromIpc = parsed.outputs;
                    else if (parsed && typeof parsed === "object")
                        root.monitorsFromIpc = Object.values(parsed);
                    else
                        root.monitorsFromIpc = [];
                } catch (e) {
                    root.monitorsFromIpc = [];
                }
            }
        }
        onExited: exitCode => {
            if (exitCode === 0)
                hyprctlClients.running = true;
            else
                root.monitorsFromIpc = [];
        }
    }

    Process {
        id: hyprctlClients
        command: root.compositorBackend === "niri" ? ["niri", "msg", "-j", "windows"]
            : root.compositorBackend === "hyprland" ? ["hyprctl", "clients", "-j"]
            : []
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const parsed = JSON.parse(data);
                    if (Array.isArray(parsed))
                        root.windowsFromIpc = parsed;
                    else if (parsed && Array.isArray(parsed.windows))
                        root.windowsFromIpc = parsed.windows;
                    else
                        root.windowsFromIpc = [];
                } catch (e) {
                    root.windowsFromIpc = [];
                }
            }
        }
        onExited: exitCode => {
            if (exitCode === 0)
                root.startGrimCapture();
            else
                root.windowsFromIpc = [];
        }
    }

    Process {
        id: grimCapture
        onExited: exitCode => {
            if (exitCode === 0) {
                overlayReadyDelay.restart();
            } else {
                console.error("[Screenshot] Failed to capture monitor snapshots");
                root.captureTimestamp = "";
                root.active = false;
            }
        }
    }

    Timer {
        id: overlayReadyDelay
        interval: 50
        onTriggered: root.active = true
    }

    // =========================================================================
    // PUBLIC FUNCTIONS
    // =========================================================================

    function startCapture() {
        if (root.compositorBackend === "") {
            console.error("[Screenshot] No supported compositor backend detected");
            root.active = false;
            root.captureTimestamp = "";
            return;
        }

        prepareCapture();
        hyprctlMonitors.running = true;
    }

    function shellEscape(str) {
        return "'" + str.replace(/'/g, "'\\''") + "'";
    }

    function tempPathForScreen(screenName) {
        if (root.captureTimestamp === "")
            return "";
        return Quickshell.cachePath(`screenshot-${root.captureTimestamp}-${screenName}.png`);
    }

    function cleanupTempFiles() {
        const paths = [];
        for (let i = 0; i < root.monitorsFromIpc.length; i++) {
            paths.push(shellEscape(tempPathForScreen(root.monitorsFromIpc[i].name)));
        }
        if (paths.length > 0) {
            Quickshell.execDetached(["sh", "-c", "rm -f " + paths.join(" ")]);
        }
        root.captureTimestamp = "";
    }

    function cancelCapture() {
        root.hasSelection = false;
        cleanupTempFiles();
        root.active = false;
    }

    function resetSelection() {
        root.editMode = false;
        root.hasSelection = false;
        root.selectionX = 0;
        root.selectionY = 0;
        root.selectionWidth = 0;
        root.selectionHeight = 0;
        root.selectedWindowTitle = "";
        root.selectedWindowClass = "";
    }

    function setMode(newMode) {
        resetSelection();
        root.mode = newMode;

        if (newMode === "screen") {
            root.selectionX = 0;
            root.selectionY = 0;
            root.selectionWidth = root.activeScreen?.width || 1920;
            root.selectionHeight = root.activeScreen?.height || 1080;
            root.hasSelection = true;
            root.selectedWindowTitle = root.activeMonitorInfo?.name || root.activeScreen?.name || "Monitor";
        }
    }

    function monitorInfoForScreen(screenName) {
        if (!screenName || !root.monitorsFromIpc || root.monitorsFromIpc.length === 0)
            return null;

        for (const output of root.monitorsFromIpc) {
            const outputName = output.name || output.output || output.connector;
            if (outputName === screenName)
                return output;
        }
        return null;
    }

    function updateActiveMonitorInfo(screenName) {
        root.activeMonitorInfo = monitorInfoForScreen(screenName);
    }

    function confirmSelection() {
        root.editMode = false;
        saveScreenshot(root.selectionX, root.selectionY, root.selectionWidth, root.selectionHeight);
    }

    function editSelection() {
        root.editMode = true;
        saveScreenshot(root.selectionX, root.selectionY, root.selectionWidth, root.selectionHeight);
    }

    function checkWindowAt(mouseX, mouseY, screenName) {
        const monitorIpc = root.monitorsFromIpc.find(m => m.name === screenName);
        if (!monitorIpc)
            return;

        const monitorX = monitorIpc.x || 0;
        const monitorY = monitorIpc.y || 0;
        const monitorId = monitorIpc.id ?? monitorIpc.idx ?? monitorIpc.index ?? monitorIpc.name;
        const activeWorkspaceId = monitorIpc.activeWorkspace?.id ?? monitorIpc.active_workspace?.id ?? monitorIpc.currentWorkspace?.id ?? monitorIpc.current_workspace_id ?? null;

        const windows = root.windowsFromIpc;
        if (!windows || windows.length === 0) {
            resetSelection();
            return;
        }

        for (let i = windows.length - 1; i >= 0; i--) {
            let win = windows[i];
            if (!win)
                continue;

            const winMonitor = win.monitor ?? win.output ?? win.output_name ?? win.outputName ?? win.name;
            const winWorkspaceId = win.workspace?.id ?? win.workspace_id ?? win.workspaceId ?? null;
            const winAt = Array.isArray(win.at) ? win.at : [win.x ?? win.layout?.x, win.y ?? win.layout?.y];
            const winSize = Array.isArray(win.size) ? win.size : [win.width ?? win.layout?.width, win.height ?? win.layout?.height];
            const winTitle = win.title || win.name || "";
            const winClass = win.class || win.app_id || win.appId || "";
            const winHidden = win.hidden || false;

            if (winMonitor !== undefined && winMonitor !== monitorId && winMonitor !== screenName)
                continue;
            if (activeWorkspaceId !== null && winWorkspaceId !== null && winWorkspaceId !== activeWorkspaceId)
                continue;
            if (!winAt || !winSize || winAt.length < 2 || winSize.length < 2)
                continue;
            if ((winTitle === "" && winClass === "") || winHidden)
                continue;

            let winX = winAt[0] - monitorX;
            let winY = winAt[1] - monitorY;
            let winW = winSize[0];
            let winH = winSize[1];

            if (mouseX >= winX && mouseX <= winX + winW && mouseY >= winY && mouseY <= winY + winH) {
                root.selectionX = winX;
                root.selectionY = winY;
                root.selectionWidth = winW;
                root.selectionHeight = winH;
                root.selectedWindowTitle = winTitle || winClass || "Window";
                root.selectedWindowClass = winClass;
                return;
            }
        }
        resetSelection();
    }

    // =========================================================================
    // PRIVATE FUNCTIONS
    // =========================================================================

    function prepareCapture() {
        root.mode = "region";
        resetSelection();
        root.activeScreen = null;

        if (Quickshell.screens && Quickshell.screens.length > 0)
            root.activeScreen = Quickshell.screens[0];

        root.updateActiveMonitorInfo(root.activeScreen?.name || "");

        root.captureTimestamp = String(Date.now());
    }

    function startGrimCapture() {
        const commands = [];
        for (const monitor of root.monitorsFromIpc) {
            const path = tempPathForScreen(monitor.name);
            commands.push(`grim -o ${shellEscape(monitor.name)} ${shellEscape(path)}`);
        }

        if (commands.length === 0) {
            console.error("[Screenshot] No monitors available for capture");
            root.captureTimestamp = "";
            root.active = false;
            return;
        }

        grimCapture.command = ["sh", "-c", commands.join(" && ")];
        grimCapture.running = true;
    }

    function saveScreenshot(x, y, width, height) {
        if (width < 5 || height < 5)
            return;

        const scale = root.activeMonitorInfo?.scale || 1;
        const monitorName = root.activeMonitorInfo?.name || root.activeScreen?.name || "";
        const sourcePath = tempPathForScreen(monitorName);

        // Per-monitor image: no monitor offset needed
        const scaledX = Math.round(x * scale);
        const scaledY = Math.round(y * scale);
        const scaledWidth = Math.round(width * scale);
        const scaledHeight = Math.round(height * scale);

        const home = Quickshell.env("HOME") || "/tmp";
        const picturesDir = Quickshell.env("XDG_PICTURES_DIR") || (home + "/Pictures/Screenshots");
        const timestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
        const outputPath = `${picturesDir}/screenshot-${timestamp}.png`;

        // Commands
        const createDir = "mkdir -p " + shellEscape(picturesDir);
        const cropImage = `magick ${shellEscape(sourcePath)} -crop ${scaledWidth}x${scaledHeight}+${scaledX}+${scaledY} +repage ${shellEscape(outputPath)}`;
        const checkAndCopy = `[ -f ${shellEscape(outputPath)} ] && wl-copy < ${shellEscape(outputPath)}`;
        const checkAndNotify = `[ -f ${shellEscape(outputPath)} ] && notify-send -i accessories-screenshot -a "Screenshot" "Screenshot Saved!" "Path: ${outputPath}"`;
        const sattyAction = `magick ${shellEscape(sourcePath)} -crop ${scaledWidth}x${scaledHeight}+${scaledX}+${scaledY} png:- | satty --filename - --output-filename ${shellEscape(outputPath)} --early-exit --init-tool brush --disable-notifications`;

        // Cleanup all per-monitor temp files
        let cleanPaths = [];
        for (let i = 0; i < root.monitorsFromIpc.length; i++)
            cleanPaths.push(shellEscape(tempPathForScreen(root.monitorsFromIpc[i].name)));
        const cleanTemp = "rm -f " + cleanPaths.join(" ");

        // Steps
        const defaultCmd = [createDir, cropImage, checkAndCopy, cleanTemp, checkAndNotify];
        const sattyCmd = `trap '${cleanTemp}' EXIT; ` + [createDir, sattyAction, checkAndCopy, checkAndNotify].join(" && ");

        const cmd = root.editMode ? sattyCmd : defaultCmd.join(" && ");

        resetSelection();
        // REMOVED cleanupTempFiles() because it causes a race condition with the crop command
        root.captureTimestamp = ""; // Just reset timestamp, file cleanup is in the sh command
        root.active = false;
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // =========================================================================
    // OVERLAY (loaded only when active)
    // =========================================================================

    Loader {
        active: root.active
        sourceComponent: Component {
            Variants {
                model: Quickshell.screens

                delegate: ScreenshotParts.ScreenshotOverlay {
                    required property var modelData
                    screen: modelData
                    screenshot: root
                }
            }
        }
    }
}
