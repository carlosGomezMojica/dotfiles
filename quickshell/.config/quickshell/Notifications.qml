import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick

// Servidor de notificaciones (sustituye a dunst) y ventana con las tarjetas, arriba a la derecha
Scope {
    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true

        // Sin tracked = true la notificación se descarta al momento
        onNotification: notification => notification.tracked = true
    }

    // `qs ipc call notifications dismissAll` (SUPER + ,) / `dismissLatest`
    IpcHandler {
        target: "notifications"
        function dismissAll(): void {
            for (const n of server.trackedNotifications.values.slice()) n.dismiss()
        }
        function dismissLatest(): void {
            const list = server.trackedNotifications.values
            if (list.length > 0) list[list.length - 1].dismiss()
        }
    }

    PanelWindow {
        // En el monitor enfocado
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        anchors { top: true; right: true }
        margins { top: 8; right: 8 }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: server.trackedNotifications.values.length > 0

        // Alto fijo: ligarlo a contentHeight deja la ventana sin mostrarse mientras está oculta.
        // La máscara limita el ratón a las tarjetas, así que el resto deja pasar los clics.
        implicitWidth: 340
        implicitHeight: screen.height - 16

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-notifications"

        // Solo las tarjetas reciben el ratón
        mask: Region { item: list }

        ListView {
            id: list
            width: parent.width
            height: contentHeight
            // De abajo arriba: la más reciente queda arriba del todo
            verticalLayoutDirection: ListView.BottomToTop
            spacing: 8
            interactive: false
            model: server.trackedNotifications

            delegate: NotificationCard {
                required property var modelData
                notification: modelData
                width: list.width
            }

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; from: 24; to: 0; duration: 180; easing.type: Easing.OutCubic }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 150 }
                NumberAnimation { property: "x"; to: 24; duration: 150; easing.type: Easing.InCubic }
            }
            displaced: Transition {
                NumberAnimation { property: "y"; duration: 180; easing.type: Easing.OutCubic }
            }
        }
    }
}
