import Quickshell
import QtQuick

// Panel de conexión bajo la cápsula de red. Se cierra al hacer clic fuera.
PopupWindow {
    id: root

    required property Item anchorItem
    property bool open: false
    property real closedAt: 0

    // Pulsar la cápsula con el panel abierto: el clic fuera ya lo cerró un instante
    // antes, así que no hay que reabrirlo
    function toggle() {
        if (!open && Date.now() - closedAt < 300) return
        open = !open
    }

    anchor.item: anchorItem
    anchor.rect.width: anchorItem.width
    anchor.rect.height: anchorItem.height + 8
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight + 8
    color: "transparent"
    grabFocus: true
    visible: open

    // El escáner wifi solo mientras el panel está abierto
    Binding {
        target: Net.wifi
        when: Net.wifi !== null
        property: "scannerEnabled"
        value: root.visible
    }

    // Clic fuera: el compositor cierra el popup, sincronizamos el estado
    onVisibleChanged: {
        if (visible) {
            Net.refreshIp()
            card.opacity = 1
            card.y = 0
        } else {
            open = false
            closedAt = Date.now()
            card.cancelPsk()
            card.opacity = 0
            card.y = -8
        }
    }

    NetworkCard {
        id: card
        width: parent.width
        opacity: 0
        y: -8

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y       { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }
}
