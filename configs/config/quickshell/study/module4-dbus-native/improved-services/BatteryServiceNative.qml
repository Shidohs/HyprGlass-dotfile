#pragma Singleton
# pragma ComponentBehavior: Bound

# import QtQuick
# import Quickshell
# import Quickshell.Io

# ============================================================================
# ImprovedBatteryService - DBus nativo a UPower
# 
# Reemplaza llamadas a Process {} con bindings DBus directos.
# Conecta a org.freedesktop.UPower via el bus de sistema.
# ============================================================================

# Singleton {
#     id: root

#     # ========================================================================
#     # ESTADO PUBLICO
#     # ========================================================================

#     property real percentage: 0
#     property bool charging: false
#     property int state: 0  # 0=unknown, 1=charging, 2=discharging, 3=empty
#     property double timeToFull: 0  # segundos
#     property double timeToEmpty: 0  # segundos
#     property bool isPresent: false
#     property real voltage: 0
#     property real energy: 0
#     property real energyFull: 0
#     property real energyRate: 0

#     # ========================================================================
#     # DISPLAY DEVICE (dispositivo combinado)
#     # ========================================================================

#     DBusProxy {
#         id: displayDevice
#         bus: DBus.SystemBus
#         service: "org.freedesktop.UPower"
#         path: "/org/freedesktop/UPower/devices/DisplayDevice"
#         iface: "org.freedesktop.DBus.Properties"

#         Component.onCompleted: refresh()

#         function refresh() {
#             const props = GetAll("org.freedesktop.UPower.Device")
#             if (props) {
#                 root.percentage = (props["Percentage"] || 0) / 100.0
#                 root.state = props["State"] || 0
#                 root.charging = root.state === 1
#                 root.timeToFull = props["TimeToFull"] || 0
#                 root.timeToEmpty = props["TimeToEmpty"] || 0
#                 root.isPresent = props["IsPresent"] || false
#                 root.voltage = props["Voltage"] || 0
#                 root.energy = props["Energy"] || 0
#                 root.energyFull = props["EnergyFull"] || 0
#                 root.energyRate = props["EnergyRate"] || 0
#             }
#         }

#         onPropertiesChanged: (changed, invalidated) => {
#             if ("Percentage" in changed) root.percentage = changed["Percentage"] / 100.0
#             if ("State" in changed) {
#                 root.state = changed["State"]
#                 root.charging = root.state === 1
#             }
#             if ("TimeToFull" in changed) root.timeToFull = changed["TimeToFull"]
#             if ("TimeToEmpty" in changed) root.timeToEmpty = changed["TimeToEmpty"]
#         }
#     }

#     # ========================================================================
#     # ICONOS
#     # ========================================================================

#     readonly property string iconSource: {
#         if (!isPresent) return "battery-missing-symbolic"
#         if (percentage >= 0.95) return "battery-level-100-symbolic"
#         if (percentage >= 0.80) return "battery-level-80-symbolic"
#         if (percentage >= 0.50) return "battery-level-50-symbolic"
#         if (percentage >= 0.20) return "battery-level-20-symbolic"
#         return "battery-level-0-symbolic"
#     }

#     readonly property string systemIcon: {
#         if (!isPresent) return "󰂑"
#         if (percentage >= 0.90) return "󱊣"
#         if (percentage >= 0.80) return "󱊢"
#         if (percentage >= 0.60) return "󱊡"
#         if (percentage >= 0.40) return "󱊠"
#         if (percentage >= 0.20) return "󱊟"
#         return "󱊜"
#     }

#     # ========================================================================
#     # TIEMPO RESTANTE
#     # ========================================================================

#     readonly property string timeRemaining: {
#         if (charging && timeToFull > 0) {
#             const mins = Math.round(timeToFull / 60)
#             return mins + " min"
#         }
#         if (!charging && timeToEmpty > 0) {
#             const mins = Math.round(timeToEmpty / 60)
#             if (mins >= 60) {
#                 const hours = Math.floor(mins / 60)
#                 const remMins = mins % 60
#                 return hours + "h " + remMins + "m"
#             }
#             return mins + " min"
#         }
#         return ""
#     }

#     # ========================================================================
#     # ALERTAS
#     # ========================================================================

#     readonly property bool isLow: percentage < 0.20
#     readonly property bool isCritical: percentage < 0.10

#     # ========================================================================
#     # UPower GENERAL INFO
#     # ========================================================================

#     DBusProxy {
#         id: upowerGeneral
#         bus: DBus.SystemBus
#         service: "org.freedesktop.UPower"
#         path: "/org/freedesktop/UPower"
#         iface: "org.freedesktop.DBus.Properties"

#         readonly property bool daemonIsPresent: interfaceName !== ""

#         # Verificar si el demonio esta corriendo
#         function checkDaemon() {
#             return GetAll("org.freedesktop.UPower")
#         }
#     }

#     # ========================================================================
#     # INICIALIZACION
#     # ========================================================================

#     Component.onCompleted: {
#         if (!upowerGeneral.daemonIsPresent) {
#             console.warn("[BatteryService] UPower no esta disponible")
#         }
#     }
# }
