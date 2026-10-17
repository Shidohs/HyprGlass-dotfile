pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services
import "./pages/"

QsPopupWindow {
    id: root

    popupWidth: 400
    popupMaxHeight: 700
    anchorSide: "right"
    moduleName: "QuickSettings"
    property string wifiPasswordTargetSsid: ""
    readonly property var pageLoaders: [
        dashboardLoader,
        wifiLoader,
        wifiPasswordLoader,
        bluetoothLoader,
        nightLightLoader,
        themeLoader,
        audioLoader,
        performanceLoader
    ]
    contentImplicitHeight: pageLoaders[pageStack.currentIndex]?.item?.implicitHeight ?? popupMaxHeight - 32

    // Named page indices to avoid magic numbers
    readonly property int pageDashboard: 0
    readonly property int pageWifi: 1
    readonly property int pageWifiPassword: 2
    readonly property int pageBluetooth: 3
    readonly property int pageNightLight: 4
    readonly property int pageTheme: 5
    readonly property int pageAudio: 6
    readonly property int pagePerformance: 7

    function pageIndexForName(pageName) {
        switch (pageName) {
        case "wifi":
            return pageWifi;
        case "wifiPassword":
            return pageWifiPassword;
        case "bluetooth":
            return pageBluetooth;
        case "nightLight":
            return pageNightLight;
        case "theme":
            return pageTheme;
        case "audio":
            return pageAudio;
        case "performance":
            return pagePerformance;
        default:
            return pageDashboard;
        }
    }

    Component.onCompleted: {
        root.visible = false;
        pageStack.currentIndex = root.pageIndexForName(QuickSettingsService.requestedPage);
        QuickSettingsService.registerWindow(root);
    }

    onClosing: pageStack.currentIndex = pageDashboard

    Component.onDestruction: QuickSettingsService.unregisterWindow(root)

    onVisibleChanged: {
        if (!visible && QuickSettingsService.visible)
            QuickSettingsService.notifyClosed();
    }

    Connections {
        target: QuickSettingsService

        function onRequestTokenChanged() {
            pageStack.currentIndex = root.pageIndexForName(QuickSettingsService.requestedPage);
            if (QuickSettingsService.visible && !root.visible)
                root.visible = true;
        }
    }

    StackLayout {
        id: pageStack
        anchors.fill: parent
        currentIndex: 0

        // ==========================
        // PAGE 0: DASHBOARD
        // ==========================
        Loader {
            id: dashboardLoader
            active: true // Always active to keep it ready after first load
            visible: pageStack.currentIndex === root.pageDashboard
            asynchronous: true
            sourceComponent: DashboardPage {
                onCloseWindow: root.closeWindow()
                onNavigateTo: page => pageStack.currentIndex = page
            }
        }

        // ==========================
        // PAGE 1: WI-FI
        // ==========================
        Loader {
            id: wifiLoader
            active: pageStack.currentIndex === root.pageWifi
            asynchronous: true
            sourceComponent: WifiPage {
                onBackRequested: pageStack.currentIndex = root.pageDashboard
                onPasswordRequested: ssid => {
                    root.wifiPasswordTargetSsid = ssid;
                    pageStack.currentIndex = root.pageWifiPassword;
                }
            }
        }

        // ==========================
        // PAGE 2: WI-FI PASSWORD
        // ==========================
        Loader {
            id: wifiPasswordLoader
            active: root.visible && pageStack.currentIndex === root.pageWifiPassword
            sourceComponent: WifiPasswordPage {
                targetSsid: root.wifiPasswordTargetSsid
                onCancelled: pageStack.currentIndex = root.pageWifi
                onConnectClicked: password => {
                    NetworkService.connect(root.wifiPasswordTargetSsid, password);
                    pageStack.currentIndex = root.pageWifi;
                }
            }
        }

        // ==========================
        // PAGE 3: BLUETOOTH
        // ==========================
        Loader {
            id: bluetoothLoader
            active: pageStack.currentIndex === root.pageBluetooth
            asynchronous: true
            sourceComponent: BluetoothPage {
                onBackRequested: pageStack.currentIndex = root.pageDashboard
            }
        }

        // ==========================
        // PAGE 4: NIGHT LIGHT
        // ==========================
        Loader {
            id: nightLightLoader
            active: pageStack.currentIndex === root.pageNightLight
            asynchronous: true
            sourceComponent: NightLightPage {
                onBackRequested: pageStack.currentIndex = root.pageDashboard
            }
        }

        // ==========================
        // PAGE 5: THEME
        // ==========================
        Loader {
            id: themeLoader
            active: pageStack.currentIndex === root.pageTheme
            asynchronous: true
            sourceComponent: ThemePage {
                onBackRequested: pageStack.currentIndex = root.pageDashboard
            }
        }



        // ==========================
        // PAGE 6: AUDIO
        // ==========================
        Loader {
            id: audioLoader
            active: pageStack.currentIndex === root.pageAudio
            asynchronous: true
            sourceComponent: AudioPage {
                onBackRequested: pageStack.currentIndex = root.pageDashboard
            }
        }

        // ==========================
        // PAGE 7: PERFORMANCE
        // ==========================
        Loader {
            id: performanceLoader
            active: pageStack.currentIndex === root.pagePerformance
            asynchronous: true
            sourceComponent: PerformancePage {
                onBackRequested: pageStack.currentIndex = root.pageDashboard
            }
        }
    }
}
