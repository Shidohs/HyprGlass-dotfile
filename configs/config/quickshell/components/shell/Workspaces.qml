pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// ============================================================================
// Workspaces — módulo de barra optimizado para Hyprland
//
// Diseño:
//  • Se suscribe a Hyprland.workspaces (modelo reactivo nativo) y al evento
//    IPC "activespecial" para special workspaces.
//  • updateModel() hace un diff mínimo sobre workspacesModel: solo inserta /
//    elimina / mueve — nunca recrea el modelo completo.
//  • focusWorkspace y toggleSpecial despachan directamente a Hyprland.dispatch.
//  • No hay timers, ni polling, ni copias de objetos innecesarias.
// ============================================================================

Item {
    id: root

    // -------------------------------------------------------------------------
    // Tamaños
    // -------------------------------------------------------------------------
    readonly property int itemW:   34
    readonly property int itemH:   34
    readonly property int activeW: 54
    readonly property int activeH: 34
    readonly property int spacing: 6

    implicitWidth:  isSpecial ? specialIndicator.width : workspacesRow.implicitWidth
    implicitHeight: activeH

    // -------------------------------------------------------------------------
    // Monitor actual (instancia por pantalla gracias a Variants en Bar.qml)
    // -------------------------------------------------------------------------
    readonly property var parentWindow:  QsWindow.window
    readonly property var parentScreen:  parentWindow?.screen ?? null

    readonly property var monitor: {
        if (!Hyprland) return null;
        return (parentScreen ? Hyprland.monitorFor(parentScreen) : null)
               ?? Hyprland.focusedMonitor
               ?? null;
    }
    readonly property string monitorName: monitor?.name ?? ""

    // -------------------------------------------------------------------------
    // Workspace activo en este monitor
    // -------------------------------------------------------------------------
    readonly property int activeId: {
        const id = Number(monitor?.activeWorkspace?.id ?? 0);
        return id > 0 ? id : 1;
    }

    // -------------------------------------------------------------------------
    // Special workspace
    // -------------------------------------------------------------------------
    property string _specialName: ""          // nombre raw del IPC

    readonly property bool   isSpecial:     _specialName !== ""
    readonly property string specialClean:  _specialName.startsWith("special:")
                                                ? _specialName.slice(8)
                                                : _specialName

    // Tabla de special workspaces conocidos
    readonly property var specialMeta: ({
        "whatsapp": { icon: "󰖣", color: Config.successColor,  label: "WhatsApp" },
        "spotify":  { icon: "󰓇", color: Config.accentColor,   label: "Music"    },
        "magic":    { icon: "󰀘", color: Config.warningColor,  label: "Magic"    }
    })

    // Caché para evitar flash al salir del special workspace
    property string _cachedIcon:  "󰀘"
    property string _cachedLabel: ""
    property color  _cachedColor: Config.accentColor

    readonly property var _specialConfig: {
        if (!isSpecial) return null;
        return specialMeta[specialClean] ?? {
            icon:  "󰀘",
            color: Config.accentColor,
            label: specialClean.charAt(0).toUpperCase() + specialClean.slice(1)
        };
    }
    on_SpecialConfigChanged: {
        if (_specialConfig) {
            _cachedIcon  = _specialConfig.icon;
            _cachedLabel = _specialConfig.label;
            _cachedColor = _specialConfig.color;
        }
    }

    // -------------------------------------------------------------------------
    // Modelo de workspaces visibles  (activo + ocupados, ordenados)
    // -------------------------------------------------------------------------
    ListModel { id: workspacesModel }

    // Recalcula el modelo con diff mínimo
    function updateModel() {
        if (!Hyprland?.workspaces) return;

        // Construye lista de ids: el activo + los que tienen ventanas
        const active = root.activeId;
        const seen   = new Set();
        const ids    = [];

        // Siempre incluir el activo
        if (active > 0) { seen.add(active); ids.push(active); }

        for (const ws of Hyprland.workspaces.values) {
            if (!ws || ws.id <= 0) continue;
            if (!seen.has(ws.id)) {
                seen.add(ws.id);
                ids.push(ws.id);
            }
        }
        ids.sort((a, b) => a - b);

        // --- diff: eliminar los que ya no existen ---
        for (let i = workspacesModel.count - 1; i >= 0; i--) {
            if (!ids.includes(workspacesModel.get(i).workspaceId))
                workspacesModel.remove(i);
        }

        // --- diff: insertar / reordenar ---
        for (let i = 0; i < ids.length; i++) {
            const tid = ids[i];
            let found = false;
            for (let j = 0; j < workspacesModel.count; j++) {
                if (workspacesModel.get(j).workspaceId === tid) {
                    if (j !== i) workspacesModel.move(j, i, 1);
                    found = true;
                    break;
                }
            }
            if (!found) workspacesModel.insert(i, { workspaceId: tid });
        }
    }

    // Re-sincronizar cuando cambia el workspace activo o la lista de workspaces
    onActiveIdChanged:                 updateModel()
    onMonitorChanged:                  updateModel()
    Component.onCompleted:             updateModel()

    Connections {
        target: Hyprland?.workspaces ?? null
        function onValuesChanged() { root.updateModel(); }
    }

    // -------------------------------------------------------------------------
    // IPC — solo gestiona "activespecial" (el resto lo cubre el modelo nativo)
    // -------------------------------------------------------------------------
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event) return;

            if (event.name === "activespecial") {
                const parts      = event.data.split(",");
                const wsName     = parts[0] ?? "";
                const evMonitor  = parts[1] ?? "";
                // Aplica solo si es este monitor o sin monitor específico
                if (evMonitor === "" || evMonitor === root.monitorName)
                    root._specialName = wsName;
            }
        }
    }

    // -------------------------------------------------------------------------
    // Acciones
    // -------------------------------------------------------------------------
    function focusWorkspace(id) {
        if (id <= 0 || id === root.activeId) return;
        Hyprland.dispatch("focusworkspaceoncurrentmonitor " + id);
    }

    function toggleSpecial() {
        if (root.specialClean)
            Hyprland.dispatch("togglespecialworkspace " + root.specialClean);
    }

    // =========================================================================
    // UI — SPECIAL WORKSPACE INDICATOR
    // =========================================================================
    Rectangle {
        id: specialIndicator
        anchors.centerIn:             parent
        anchors.verticalCenterOffset: isSpecial ? 0 : 5

        visible: opacity > 0
        opacity: isSpecial ? (specialHover.hovered ? 0.8 : 1.0) : 0
        scale:   isSpecial ? 1.0 : 0.9

        width:  specialRow.implicitWidth + Config.padding * 3
        height: root.activeH
        radius: Config.radius

        color:        root._cachedColor
        border.width: 1

        Behavior on opacity { NumberAnimation { duration: Config.animDurationShort } }
        Behavior on scale   { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }
        Behavior on color   { ColorAnimation   { duration: Config.animDuration } }

        Row {
            id: specialRow
            anchors.centerIn: parent
            spacing: Config.padding * 0.8

            Text {
                text:  root._cachedIcon
                color: Config.textReverseColor
                font { family: Config.font; pixelSize: Config.fontSizeLarge }
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text:  root._cachedLabel
                color: Config.textReverseColor
                font { family: Config.font; bold: true; pixelSize: Config.fontSizeNormal }
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        TapHandler { onTapped: root.toggleSpecial() }
        HoverHandler { id: specialHover; cursorShape: Qt.PointingHandCursor }
    }

    // =========================================================================
    // UI — WORKSPACES NORMALES
    // =========================================================================
    Item {
        id: workspacesContainer
        anchors.centerIn: parent
        width:  workspacesRow.implicitWidth
        height: parent.height

        visible: !root.isSpecial
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Config.animDurationShort } }

        Row {
            id: workspacesRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.spacing

            Repeater {
                model: workspacesModel

                delegate: Rectangle {
                    id: wsItem
                    required property int workspaceId
                    readonly property bool active: workspaceId === root.activeId

                    width:  active ? root.activeW : root.itemW
                    height: active ? root.activeH : root.itemH
                    radius: width / 2.4

                    color:        active ? Config.accentColor   : Config.surface2Color
                    border.width: active ? 0 : 1
                    border.color: Qt.alpha(Config.textColor, 0.2)
                    opacity:      wsHover.hovered ? 0.8 : 1.0

                    Behavior on width   { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutExpo } }
                    Behavior on color   { ColorAnimation  { duration: Config.animDuration } }
                    Behavior on opacity { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutExpo } }

                    Text {
                        anchors.centerIn: parent
                        text:      wsItem.workspaceId
                        color:     wsItem.active ? Config.textReverseColor : Config.textColor
                        scale:     wsItem.active ? 1.0 : 0.92
                        font {
                            family:    Config.font
                            pixelSize: Config.fontSizeLarge
                            bold:      wsItem.active
                        }
                        Behavior on scale { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation  { duration: Config.animDuration } }
                    }

                    TapHandler { onTapped: root.focusWorkspace(wsItem.workspaceId) }
                    HoverHandler {
                        id: wsHover
                        cursorShape: wsItem.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                    }
                }
            }
        }
    }
}
