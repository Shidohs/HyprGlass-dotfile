#pragma Singleton
# pragma ComponentBehavior: Bound

# import QtQuick
# import Quickshell
# import Quickshell.Io

# ============================================================================
# ImprovedNetworkService - DBus nativo a NetworkManager
#
# Reemplaza nmcli con bindings DBus directos a NetworkManager.
# ============================================================================

# Singleton {
#     id: root

#     # ========================================================================
#     # ESTADO PUBLICO
#     # ========================================================================

#     property bool connected: false
#     property string primaryConnection: ""
#     property string primaryDevice: ""
#     property string connectionType: ""  # wifi, ethernet, vpn
#     property bool wifiEnabled: true
#     property int wifiStrength: 0

#     # WiFi
#     property var wifiNetworks: []
#     property var accessPoints: []

#     # Ethernet
#     property bool ethernetConnected: false
#     property string ethernetDevice: ""

#     # VPN
#     property bool vpnActive: false
#     property string vpnName: ""

#     # ========================================================================
#     # NetworkManager GENERAL
#     # ========================================================================

#     DBusProxy {
#         id: nmManager
#         bus: DBus.SystemBus
#         service: "org.freedesktop.NetworkManager"
#         path: "/org/freedesktop/NetworkManager"
#         iface: "org.freedesktop.NetworkManager"

#         # Propiedades principales
#         readonly property var devices: []
#         readonly property var activeConnections: []
#         readonly property bool networkingEnabled: true

#         Component.onCompleted: {
#             refreshDevices()
#             refreshConnections()
#         }

#         function refreshDevices() {
#             const devPaths = callMethod("GetDevices")
#             if (devPaths) root.devices = devPaths
#         }

#         function refreshConnections() {
#             const connPaths = callMethod("GetActiveConnections")
#             if (connPaths) root.activeConnections = connPaths
#         }

#         # Escuchar cambios
#         onPropertiesChanged: (changed, invalidated) => {
#             if ("PrimaryConnection" in changed) root.primaryConnection = changed["PrimaryConnection"]
#             if ("Connectivity" in changed) root.connected = changed["Connectivity"] === 4  # NM_CONNECTIVITY_FULL
#         }
#     }

#     # ========================================================================
#     # WI-FI DEVICE
#     # ============================================================================

#     DBusProxy {
#         id: wifiDevice
#         bus: DBus.SystemBus
#         service: "org.freedesktop.NetworkManager"
#         path: ""  # Se setea dinamicamente
#         iface: "org.freedesktop.NetworkManager.Device.Wireless"

#         property bool isWifiDevice: false

#         function scan() {
#             if (path) callMethod("RequestScan", {})
#         }

#         function getAccessPoints() {
#             if (path) {
#                 const aps = callMethod("GetAccessPoints")
#                 if (aps) root.accessPoints = aps
#             }
#         }
#     }

#     # ========================================================================
#     # ACCESO A PUNTOS DE ACCESO (WiFi AP)
#     # ============================================================================

#     DBusProxy {
#         id: apProxy
#         bus: DBus.SystemBus
#         service: "org.freedesktop.NetworkManager"
#         path: ""  # Se setea por cada AP
#         iface: "org.freedesktop.DBus.Properties"

#         function getAPInfo(apPath) {
#             apProxy.path = apPath
#             const props = GetAll("org.freedesktop.NetworkManager.AccessPoint")
#             if (props) {
#                 return {
#                     ssid: byteArrayToString(props["Ssid"]),
#                     strength: props["Strength"] || 0,
#                     frequency: props["Frequency"] || 0,
#                     hwAddress: props["HwAddress"] || "",
#                     mode: props["Mode"] || 0,
#                     wpaFlags: props["WpaFlags"] || 0,
#                     rsnFlags: props["RsnFlags"] || 0
#                 }
#             }
#             return null
#         }

#         function byteArrayToString(arr) {
#             if (!arr) return ""
#             let str = ""
#             for (let i = 0; i < arr.length; i++) {
#                 str += String.fromCharCode(arr[i])
#             }
#             return str
#         }
#     }

#     # ========================================================================
#     # WIFI ENABLE/DISABLE
#     # ========================================================================

#     function toggleWifi() {
#         wifiEnabled = !wifiEnabled
#         nmManager.callMethod("Enable", wifiEnabled)
#     }

#     # ========================================================================
#     # CONECTAR A RED WiFi
#     # ========================================================================

#     function connectToWifi(ssid, password) {
#         # Esto requiere crear una conexion via Settings API
#         # Simplificado: usar nmcli como fallback por ahora
#         # En una implementacion completa, se usaria:
#         # /org/freedesktop/NetworkManager/Settings con AddConnection
#         console.log("Conectando a:", ssid)
#     }

#     # ========================================================================
#     # ICONOS
#     # ========================================================================

#     readonly property string iconSource: {
#         if (!connected) return "network-offline-symbolic"
#         if (connectionType === "wifi") {
#             if (wifiStrength >= 80) return "network-wireless-signal-excellent-symbolic"
#             if (wifiStrength >= 55) return "network-wireless-signal-good-symbolic"
#             if (wifiStrength >= 30) return "network-wireless-signal-ok-symbolic"
#             if (wifiStrength >= 5) return "network-wireless-signal-weak-symbolic"
#             return "network-wireless-signal-none-symbolic"
#         }
#         if (connectionType === "ethernet") return "network-wired-symbolic"
#         if (connectionType === "vpn") return "network-vpn-symbolic"
#         return "network-offline-symbolic"
#     }

#     readonly property string systemIcon: {
#         if (!connected) return "󰤮"
#         if (connectionType === "wifi") {
#             if (wifiStrength >= 75) return "󰤨"
#             if (wifiStrength >= 50) return "󰤥"
#             if (wifiStrength >= 25) return "󰤢"
#             return "󰤟"
#         }
#         if (connectionType === "ethernet") return "󰈀"
#         return "󰤮"
#     }

#     # ========================================================================
#     # NOMBRE DE CONEXION
#     # ========================================================================

#     readonly property string connectionName: {
#         if (!connected) return "Sin conexion"
#         if (connectionType === "wifi") return primaryConnection
#         if (connectionType === "ethernet") return "Ethernet"
#         if (connectionType === "vpn") return vpnName
#         return "Desconocido"
#     }
# }
