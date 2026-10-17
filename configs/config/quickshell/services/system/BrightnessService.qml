pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    // ========================================================================
    // PUBLIC PROPERTIES - BRIGHTNESS
    // ========================================================================

    property real brightness: 1.0
    property int maxBrightness: 100
    property int currentBrightness: 100
    property int _pendingBrightnessPercent: -1
    readonly property bool available: backlightDevice !== ""
    property string backlightDevice: ""
    readonly property string brightnessPath: available ? ("/sys/class/backlight/" + backlightDevice + "/brightness") : ""
    readonly property int percentage: Math.round(brightness * 100)

    readonly property string icon: {
        if (brightness <= 0.1)
            return "󰃞";
        if (brightness <= 0.3)
            return "󰃟";
        if (brightness <= 0.6)
            return "󰃝";
        return "󰃠";
    }

    // ========================================================================
    // PUBLIC PROPERTIES - NIGHT LIGHT (HYPRSUNSET)
    // ========================================================================

    property bool nightLightEnabled: StateService.get("nightLight.enabled", false)

    // Temperature in Kelvin (1000 = very warm/orange, 6500 = daylight)
    // Slider goes from 0.0 to 1.0, mapped to 2500K - 5500K
    property int nightLightTemperature: 4000

    // Intensity as a 0.0 - 1.0 value for the slider
    // 0.0 = warmer (2500K), 1.0 = cooler (5500K)
    property real nightLightIntensity: StateService.get("nightLight.intensity", 0.5)

    // Night light icon
    readonly property string nightLightIcon: nightLightEnabled ? "󰌵" : "󰌶"
    property bool hyprsunsetReady: false
    property bool _nightLightSyncPending: false

    // ========================================================================
    // INITIALIZATION
    // ========================================================================

    Component.onCompleted: {
        detectBacklight.running = true;
        // ensureHyprsunsetRunning starts independently (night light doesn't need backlight)
        ensureHyprsunsetRunning.running = true;
    }

    // Connection with StateService to load persisted state
    Connections {
        target: StateService

        function onStateLoaded() {
            // Load night light state
            root.nightLightEnabled = StateService.get("nightLight.enabled", false);
            root.nightLightIntensity = StateService.get("nightLight.intensity", 0.5);
            root.updateTemperatureFromIntensity();

            console.log("[Brightness] Loaded state - enabled:", root.nightLightEnabled, "intensity:", root.nightLightIntensity);

            root._queueNightLightSync();
        }
    }

    Timer {
        id: brightnessApplyDebounce
        interval: 75
        onTriggered: {
            if (root._pendingBrightnessPercent < 0)
                return;
            if (setBrightnessProc.running) {
                brightnessApplyDebounce.restart();
                return;
            }

            const percentValue = root._pendingBrightnessPercent;
            root._pendingBrightnessPercent = -1;
            setBrightnessProc._requestedPercent = percentValue;
            setBrightnessProc.command = ["brightnessctl", "set", percentValue.toString() + "%"];
            setBrightnessProc.running = true;
        }
    }

    Timer {
        id: nightLightSyncDebounce
        interval: 120
        onTriggered: root._flushNightLightSync()
    }

    // ========================================================================
    // INTERNAL FUNCTIONS
    // ========================================================================

    // Converts intensity (0-1) to Kelvin temperature
    function updateTemperatureFromIntensity() {
        // 0.0 = 2500K (very warm), 1.0 = 5500K (less warm)
        nightLightTemperature = Math.round(2500 + (nightLightIntensity * 3000));
    }

    // Converts Kelvin temperature to intensity (0-1)
    function updateIntensityFromTemperature() {
        nightLightIntensity = (nightLightTemperature - 2500) / 3000;
    }

    function _queueNightLightSync() {
        root._nightLightSyncPending = true;
        nightLightSyncDebounce.restart();
    }

    function _flushNightLightSync() {
        if (!root._nightLightSyncPending)
            return;
        if (!root.hyprsunsetReady || enableNightLightProc.running || disableNightLightProc.running || restartAndEnableProc.running) {
            nightLightSyncDebounce.restart();
            return;
        }

        root._nightLightSyncPending = false;
        if (root.nightLightEnabled) {
            enableNightLightProc.command = ["hyprctl", "hyprsunset", "temperature", root.nightLightTemperature.toString()];
            enableNightLightProc.running = true;
            return;
        }

        disableNightLightProc.running = true;
    }

    // ========================================================================
    // BACKLIGHT DETECTION
    // ========================================================================

    Process {
        id: detectBacklight
        command: ["bash", "-c", "ls /sys/class/backlight/ 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: data => {
                const device = data.trim();
                if (device !== "") {
                    root.backlightDevice = device;
                    getMaxBrightness.running = true;
                }
            }
        }
    }

    Process {
        id: getMaxBrightness
        command: ["bash", "-c", "cat /sys/class/backlight/" + root.backlightDevice + "/max_brightness 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                const max = parseInt(data.trim());
                if (!isNaN(max) && max > 0) {
                    root.maxBrightness = max;
                    getCurrentBrightness.running = true;
                }
            }
        }
    }

    Process {
        id: getCurrentBrightness
        command: ["bash", "-c", "cat /sys/class/backlight/" + root.backlightDevice + "/brightness 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                const current = parseInt(data.trim());
                if (!isNaN(current)) {
                    root.currentBrightness = current;
                    root.brightness = current / root.maxBrightness;
                }
            }
        }
    }

    FileView {
        path: root.brightnessPath
        watchChanges: root.available
        onFileChanged: {
            if (!getCurrentBrightness.running)
                getCurrentBrightness.running = true;
        }
    }

    // ========================================================================
    // PUBLIC FUNCTIONS - BRIGHTNESS
    // ========================================================================

    function setBrightness(value) {
        if (!root.available)
            return;
        const clamped = Math.max(0.05, Math.min(1.0, value));
        const percentValue = Math.round(clamped * 100);
        if (percentValue === Math.round(root.brightness * 100) && root._pendingBrightnessPercent === -1)
            return;

        root.brightness = clamped;
        root._pendingBrightnessPercent = percentValue;
        brightnessApplyDebounce.restart();
    }

    function increaseBrightness() {
        setBrightness(brightness + 0.05);
    }

    function decreaseBrightness() {
        setBrightness(brightness - 0.05);
    }

    property real lastBrightness: 1.0

    function toggleBrightness() {
        if (brightness > 0.1) {
            lastBrightness = brightness;
            setBrightness(0.05);
        } else {
            setBrightness(lastBrightness);
        }
    }

    // ========================================================================
    // PUBLIC FUNCTIONS - NIGHT LIGHT
    // ========================================================================

    function toggleNightLight() {
        if (nightLightEnabled) {
            disableNightLight();
        } else {
            enableNightLight();
        }
    }

    function enableNightLight() {
        nightLightEnabled = true;
        StateService.set("nightLight.enabled", true);
        root._queueNightLightSync();
    }

    function disableNightLight() {
        nightLightEnabled = false;
        StateService.set("nightLight.enabled", false);
        root._queueNightLightSync();
    }

    // Set the intensity and apply if active
    function setNightLightIntensity(intensity) {
        nightLightIntensity = Math.max(0.0, Math.min(1.0, intensity));
        updateTemperatureFromIntensity();
        StateService.set("nightLight.intensity", nightLightIntensity);

        if (nightLightEnabled)
            root._queueNightLightSync();
    }

    function setNightLightTemperature(temp) {
        nightLightTemperature = Math.max(2500, Math.min(5500, temp));
        updateIntensityFromTemperature();
        StateService.set("nightLight.intensity", nightLightIntensity);

        if (nightLightEnabled)
            root._queueNightLightSync();
    }

    // Apply the current temperature
    function applyNightLight() {
        root._queueNightLightSync();
    }

    // ========================================================================
    // PROCESSES - BRIGHTNESS
    // ========================================================================

    Process {
        id: setBrightnessProc
        property int _requestedPercent: -1

        onExited: {
            getCurrentBrightness.running = true;
            if (root._pendingBrightnessPercent >= 0 && root._pendingBrightnessPercent !== _requestedPercent)
                brightnessApplyDebounce.restart();
        }
    }

    // ========================================================================
    // PROCESSES - NIGHT LIGHT (HYPRSUNSET)
    // ========================================================================

    Process {
        id: ensureHyprsunsetRunning
        command: ["bash", "-c", `
            if ! pgrep -x hyprsunset >/dev/null 2>&1; then
                hyprsunset &
                disown
                sleep 0.5
            fi
        `]
        onExited: {
            root.hyprsunsetReady = true;
            if (!StateService.isLoading)
                root._queueNightLightSync();
        }
    }

    Process {
        id: enableNightLightProc
        stdout: SplitParser {
            onRead: data => {
                console.log("[Brightness] Enable night light response:", data);
            }
        }
        stderr: SplitParser {
            onRead: data => {
                console.error("[Brightness] Enable night light error:", data);
                if ((data.includes("error") || data.includes("failed")) && !restartAndEnableProc.running) {
                    root.hyprsunsetReady = false;
                    restartAndEnableProc.running = true;
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                console.log("[Brightness] Night light enabled at", root.nightLightTemperature, "K");
            }
        }
    }

    Process {
        id: restartAndEnableProc
        command: ["bash", "-c", `
            pkill -x hyprsunset 2>/dev/null
            sleep 0.2
            hyprsunset &
            disown
            sleep 0.5
            hyprctl hyprsunset temperature ` + root.nightLightTemperature + `
        `]
        onExited: {
            root.hyprsunsetReady = true;
            if (root.nightLightEnabled)
                root._queueNightLightSync();
        }
    }

    Process {
        id: disableNightLightProc
        command: ["hyprctl", "hyprsunset", "identity"]
        onExited: (exitCode, exitStatus) => {
            console.log("[Brightness] Night light disabled");
        }
    }
}
