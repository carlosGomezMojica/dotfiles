import Quickshell
import QtQuick

// Panel desplegable bajo el icono de batería. Se cierra al hacer clic fuera.
PopupWindow {
    id: root

    required property Item anchorItem
    property bool open: false
    // Distancia desde el borde derecho del icono al borde derecho de la cápsula
    property real rightInset: 16
    property real closedAt: 0

    // Pulsar el icono con el panel abierto: el clic fuera ya lo cerró un instante
    // antes, así que no hay que reabrirlo
    function toggle() {
        if (!open && Date.now() - closedAt < 300) return
        open = !open
    }

    anchor.item: anchorItem
    anchor.rect.width: anchorItem.width + rightInset
    anchor.rect.height: anchorItem.height + 14
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight + 8
    color: "transparent"
    grabFocus: true
    visible: open

    // Clic fuera: el compositor cierra el popup, sincronizamos el estado
    onVisibleChanged: {
        if (visible) {
            card.reloadCycles()
            card.opacity = 1
            card.y = 0
        } else {
            open = false
            closedAt = Date.now()
            card.opacity = 0
            card.y = -8
        }
    }

    BatteryCard {
        id: card
        width: parent.width
        opacity: 0
        y: -8

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y       { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }
}
