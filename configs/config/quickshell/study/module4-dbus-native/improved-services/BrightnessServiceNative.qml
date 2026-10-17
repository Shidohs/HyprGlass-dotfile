#pragma Singleton
# pragma ComponentBehavior: Bound

# import QtQuick
# import Quickshell
# import Quickshell.Io

# ============================================================================
# ImprovedBrightnessService - DBus nativo a UPower/Logind
#
# Reemplaza llamadas a brightnessctl con bindings DBus directos.
# Usa org.freedesktop.login1 para backlight y org.freedesktop.UPower para KMS.
# ============================================================================

# Singleton {
#     id: root

#     # ========================================================================
#     # ESTADO PUBLICO
#     # ========================================================================

#     property real brightness: 0      # 0.0 - 1.0
#     property int maxBrightness: 0
#     property int currentBrightness: 0
#     property bool available: false
#     property string displayPath: ""

#     # ========================================================================
#     # DBus: logind para backlight
#     # ========================================================================

#     # logind expone metodos para controlar el backlight via SetBrightness
#     DBusProxy {
#         id: logind
#         bus: DBus.SystemBus
#         service: "org.freedesktop.login1"
#         path: "/org/freedesktop/login1/session/auto"
#         iface: "org.freedesktop.login1.Session"

#         Component.onCompleted: {
#             # Intentar leer el backlight actual
#             probeBrightness()
#         }

#         function probeBrightness() {
#             # Leer dispositivos de backlight disponibles
#             try {
#                 const devices = GetAll("org.freedesktop.login1.Session")
#                 if (devices && devices["BacklightDevices"]) {
#                     root.available = true
#                 }
#             } catch(e) {
#                 # Fallback: intentar via sysfs
#                 probeSysfs()
#             }
#         }

#         function setBrightness(value) {
#             # value es 0.0 - 1.0
#             const absolute = Math.round(value * root.maxBrightness)
#             callMethod("SetBrightness", "backlight", root.displayPath, absolute)
#         }
#     }

#     # ========================================================================
#     # Fallback: lectura directa de sysfs
#     # ========================================================================

#     readonly property string sysfsPath: "/sys/class/backlight/"

#     Process {
#         id: probeProc
#         command: ["bash", "-c", "ls " + root.sysfsPath + " | head -1"]

#         stdout: SplitParser {
#             onRead: (data) => {
#                 const device = data.trim()
#                 if (device) {
#                     root.displayPath = device
#                     root.available = true
#                     readMaxProc.command = ["cat", root.sysfsPath + device + "/max_brightness"]
#                     readMaxProc.running = true
#                 }
#             }
#         }
#     }

#     Process {
#         id: readMaxProc
#         stdout: SplitParser {
#             onRead: (data) => {
#                 root.maxBrightness = parseInt(data.trim()) || 100
#                 readCurrentProc.running = true
#             }
#         }
#     }

#     Process {
#         id: readCurrentProc
#         command: ["cat", root.sysfsPath + root.displayPath + "/actual_brightness"]
#         stdout: SplitParser {
#             onRead: (data) => {
#                 root.currentBrightness = parseInt(data.trim()) || 0
#                 root.brightness = root.maxBrightness > 0 ? root.currentBrightness / root.maxBrightness : 0
#             }
#         }
#     }

#     # ========================================================================
#     # API PUBLICA
#     # ========================================================================

#     function set(newBrightness) {
#         root.brightness = Math.max(0, Math.min(1, newBrightness))
#         root.currentBrightness = Math.round(root.brightness * root.maxBrightness)

#         if (root.available && root.displayPath) {
#             setBrightnessProc.command = [
#                 "bash", "-c",
#                 "echo " + root.currentBrightness + " > " + root.sysfsPath + root.displayPath + "/brightness"
#             ]
#             setBrightnessProc.running = true
#         }
#     }

#     function increase(step) {
#         set(root.brightness + (step || 0.05))
#     }

#     function decrease(step) {
#         set(root.brightness - (step || 0.05))
#     }

#     Process {
#         id: setBrightnessProc
#     }

#     # ========================================================================
#     # INICIALIZACION
#     # ========================================================================

#     Component.onCompleted: {
#         probeProc.running = true
#     }
# }
