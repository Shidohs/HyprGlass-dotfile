pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property var accessPoints: []
    property var savedSsids: []
    property bool wifiEnabled: true
    property string wifiInterface: ""
    property string connectingSsid: ""
    property string ethernetInterface: ""
    property bool ethernetConnected: false
    property string ethernetConnection: ""
    property int refreshCycle: 0
    readonly property bool wifiAvailable: wifiInterface !== ""
    readonly property bool networkUiActive: WindowManagerService.activeModules["QuickSettings"] === true
    readonly property string ethernetIcon: "󰈀"
    readonly property bool scanning: rescanProc.running
    property bool isToggling: false
    readonly property string iconSource: {
        const activeNetwork = accessPoints.find(ap => ap.active === true);
        if (activeNetwork) {
            const signal = activeNetwork.signal;
            if (signal > 80) return "network-wireless-signal-excellent-symbolic";
            if (signal > 60) return "network-wireless-signal-good-symbolic";
            if (signal > 40) return "network-wireless-signal-ok-symbolic";
            if (signal > 20) return "network-wireless-signal-weak-symbolic";
            return "network-wireless-signal-none-symbolic";
        }
        if (ethernetConnected) return "network-wired-symbolic";
        if (!wifiEnabled) return "network-wireless-offline-symbolic";
        return "network-wireless-no-route-symbolic";
    }

    readonly property string systemIcon: {
        const activeNetwork = accessPoints.find(ap => ap.active === true);
        if (activeNetwork)
            return getWifiIcon(activeNetwork.signal);
        if (ethernetConnected)
            return ethernetIcon;
        if (!wifiEnabled)
            return "󰤮";
        return "󰤫";
    }

    // --- FUNCTIONS ---

    function splitTerseLine(line, expectedParts) {
        var parts = [];
        var current = "";
        var escaped = false;

        for (var i = 0; i < line.length; i++) {
            const ch = line[i];
            if (escaped) {
                current += ch;
                escaped = false;
                continue;
            }
            if (ch === "\\") {
                escaped = true;
                continue;
            }
            if (ch === ":") {
                parts.push(current);
                current = "";
                continue;
            }
            current += ch;
        }
        parts.push(current);

        if (expectedParts && parts.length < expectedParts)
            return [];
        return parts;
    }

    function getWifiIcon(signal) {
        if (signal > 80)
            return "󰤨";
        if (signal > 60)
            return "󰤥";
        if (signal > 40)
            return "󰤢";
        if (signal > 20)
            return "󰤟";
        return "󰤫";
    }

    function _runProcess(proc) {
        if (proc && !proc.running)
            proc.running = true;
    }

    function refreshNetworkState(forceDetailed) {
        const detailed = forceDetailed === true;
        const shouldRefreshInterfaces = detailed || root.refreshCycle % 5 === 0 || root.wifiInterface === "" || root.ethernetInterface === "";
        const shouldRefreshWifiLists = detailed
            || root.networkUiActive
            || root.scanning
            || root.connectingSsid !== ""
            || (root.wifiEnabled && root.wifiAvailable && (root.refreshCycle % 5 === 0 || root.accessPoints.length === 0));

        if (shouldRefreshInterfaces)
            root._runProcess(findInterfaceProc);

        root._runProcess(statusProc);
        root._runProcess(getEthernetProc);

        if (shouldRefreshWifiLists) {
            root._runProcess(getSavedProc);
            root._runProcess(getNetworksProc);
        }
    }

    // Status text
    readonly property string statusText: {
        const activeNetwork = accessPoints.find(ap => ap.active === true);

        // If there is an active network, return the SSID
        if (activeNetwork)
            return activeNetwork.ssid || "Red oculta";

        // Show connecting state
        if (connectingSsid !== "")
            return "Conectando...";

        if (ethernetConnected)
            return ethernetConnection || "Ethernet";

        if (!wifiEnabled)
            return "Apagado";

        // If enabled but not connected
        return "Encendido";
    }

    readonly property string ethernetStatusText: ethernetConnected ? (ethernetConnection || "Conectado") : "Desconectado"

    function toggleWifi() {
        if (root.isToggling || toggleWifiProc.running)
            return;
            
        root.isToggling = true;
        const targetState = !root.wifiEnabled;
        
        // Optimistic update
        root.wifiEnabled = targetState;
        
        const cmd = targetState ? "on" : "off";
        toggleWifiProc.command = ["nmcli", "radio", "wifi", cmd];
        toggleWifiProc.running = true;
    }

    function scan() {
        if (!scanning)
            rescanProc.running = true;
    }

    function disconnect() {
        if (wifiInterface !== "") {
            console.log("Disconnecting interface: " + wifiInterface);
            disconnectProc.command = ["nmcli", "dev", "disconnect", wifiInterface];
            disconnectProc.running = true;
        }
    }

    function connect(ssid, password) {
        // SECURITY FIX: Hash SSID before logging to avoid exposing location info
        const hashedSsid = Qt.md5(ssid).substring(0, 8);
        console.log("[Network] Attempting to connect to network [" + hashedSsid + "]");
        root.connectingSsid = ssid; // Mark which one we are trying

        if (password && password.length > 0) {
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        } else {
            // Try connecting using saved profile
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        }
        connectProc.running = true;
    }

    function forget(ssid) {
        // SECURITY FIX: Hash SSID before logging
        const hashedSsid = Qt.md5(ssid).substring(0, 8);
        console.log("[Network] Forgetting network [" + hashedSsid + "]");
        forgetProc.command = ["nmcli", "connection", "delete", "id", ssid];
        forgetProc.running = true;
    }

    // Internal function to clean up failed connections
    function cleanUpBadConnection(ssid) {
        console.warn("Connection failed. Removing invalid profile for: " + ssid);
        // Uses forgetProc to delete, since it is the same logic
        forget(ssid);
    }

    // --- PROCESSES ---

    // Connection Process
    Process {
        id: connectProc

        stdout: SplitParser {
            onRead: data => console.log("[Wifi] " + data)
        }
        stderr: SplitParser {
            onRead: data => console.error("[Wifi Error] " + data)
        }

        onExited: code => {
            // If exit code is 0, success. Otherwise, there was an error (wrong password, timeout, etc).
            if (code !== 0) {
                console.error("Failed to connect. Exit code: " + code);

                // IF FAILED: Delete the created profile so it doesn't remain incorrectly marked as "Saved"
                if (root.connectingSsid !== "") {
                    root.cleanUpBadConnection(root.connectingSsid);
                }
            } else {
                console.log("Connected successfully!");
            }

            // Reset state and update lists
            root.connectingSsid = "";
            root.refreshNetworkState(true);
        }
    }

    // Detect Wifi Interface
    Process {
        id: findInterfaceProc
        command: ["nmcli", "-g", "DEVICE,TYPE", "device"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                const lines = trimmed.length > 0 ? trimmed.split("\n") : [];
                root.wifiInterface = "";
                root.ethernetInterface = "";
                lines.forEach(line => {
                    const parts = line.split(":");
                    if (parts.length >= 2 && parts[1] === "wifi") {
                        root.wifiInterface = parts[0];
                    } else if (parts.length >= 2 && parts[1] === "ethernet") {
                        root.ethernetInterface = parts[0];
                    }
                });
            }
        }
    }

    // Status Monitor (Enabled/Disabled)
    Process {
        id: statusProc
        command: ["nmcli", "radio", "wifi"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const newState = (data.trim() === "enabled");
                if (root.wifiEnabled !== newState && !root.isToggling) {
                    root.wifiEnabled = newState;
                }
                if (!newState)
                    root.accessPoints = [];
            }
        }
    }

    // Toggle On/Off
    Process {
        id: toggleWifiProc
        onExited: {
            root.isToggling = false;
            root.refreshNetworkState(true);
        }
    }

    // Rescan (Refresh)
    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: root.refreshNetworkState(true)
    }

    // Disconnect
    Process {
        id: disconnectProc
        onExited: root.refreshNetworkState(true)
    }

    // Forget Network
    Process {
        id: forgetProc
        // The command is defined dynamically before running
        onExited: root.refreshNetworkState(true)
    }

    // ── NATIVE EVENT SUBSCRIPTION (NO POLLING) ──
    Process {
        id: nmMonitorProc
        command: ["nmcli", "monitor"]
        running: true
        
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim() !== "") {
                    refreshDebounce.restart();
                }
            }
        }
    }

    Timer {
        id: refreshDebounce
        interval: 1000
        onTriggered: {
            root.refreshCycle += 1;
            root.refreshNetworkState(false);
        }
    }

    Component.onCompleted: root.refreshNetworkState(true)

    // List Saved Networks
    Process {
        id: getSavedProc
        command: ["nmcli", "-t", "-e", "yes", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                const lines = trimmed.length > 0 ? trimmed.split("\n") : [];
                var savedList = [];
                lines.forEach(line => {
                    const parts = root.splitTerseLine(line, 2);
                    if (parts.length >= 2 && parts[1] === "802-11-wireless") {
                        savedList.push(parts[0]);
                    }
                });
                root.savedSsids = savedList;
            }
        }
    }

    // List Available Networks (Scan)
    Process {
        id: getNetworksProc
        command: ["nmcli", "-t", "-e", "yes", "-f", "IN-USE,SIGNAL,SSID,SECURITY,BSSID,CHAN,RATE", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                const lines = trimmed.length > 0 ? trimmed.split("\n") : [];
                var tempParams = [];
                const seen = new Set();

                lines.forEach(line => {
                    if (line.length < 5)
                        return;
                    const parts = root.splitTerseLine(line, 7);
                    if (parts.length < 7)
                        return;

                    const inUse = parts[0] === "*";
                    const signal = parseInt(parts[1]) || 0;
                    const ssid = parts[2];
                    const security = parts[3];
                    const bssid = parts[4];
                    const channel = parts[5];
                    const rate = parts[6];

                    if (!ssid)
                        return;
                    if (seen.has(ssid))
                        return; // Avoid visual duplicates
                    seen.add(ssid);

                    const isSaved = root.savedSsids.includes(ssid);

                    tempParams.push({
                        ssid: ssid,
                        signal: signal,
                        active: inUse,
                        secure: security.length > 0 && security !== "--",
                        securityType: security || "Abierta",
                        saved: isSaved,
                        bssid: bssid,
                        channel: channel,
                        rate: rate
                    });
                });

                // Sort: Connected > Saved > Signal
                tempParams.sort((a, b) => {
                    if (a.active)
                        return -1;
                    if (b.active)
                        return 1;
                    if (a.saved && !b.saved)
                        return -1;
                    if (!a.saved && b.saved)
                        return 1;
                    return b.signal - a.signal;
                });

                root.accessPoints = tempParams;
            }
        }
    }

    // Ethernet Status
    Process {
        id: getEthernetProc
        command: ["nmcli", "-t", "-e", "yes", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                const lines = trimmed.length > 0 ? trimmed.split("\n") : [];
                var connected = false;
                var connectionName = "";
                var iface = "";

                lines.forEach(line => {
                    if (line.length < 5)
                        return;
                    const parts = root.splitTerseLine(line, 4);
                    if (parts.length < 4)
                        return;
                    const type = parts[1];
                    if (type !== "ethernet")
                        return;
                    if (!iface)
                        iface = parts[0];

                    const state = parts[2];
                    const connection = parts[3];
                    if (state === "connected") {
                        connected = true;
                        connectionName = connection && connection !== "--" ? connection : "Ethernet";
                        iface = parts[0];
                    }
                });

                root.ethernetConnected = connected;
                root.ethernetConnection = connected ? connectionName : "";
                if (iface !== "")
                    root.ethernetInterface = iface;
            }
        }
    }
}
