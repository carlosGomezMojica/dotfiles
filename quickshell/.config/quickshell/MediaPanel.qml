import Quickshell
import QtQuick

// Panel multimedia bajo la cápsula de indicadores (al pulsarla). Se cierra al hacer clic fuera.
PopupWindow {
    id: root

    required property Item anchorItem
    property bool open: false
    property real closedAt: 0

    // Pulsar la cápsula con el panel abierto: el clic fuera ya lo cerró un instante
    // antes, así que no hay que reabrirlo
    function handleKey(event) { return open && card.handleKey(event) }

    function toggle() {
        if (!open && Date.now() - closedAt < 300) return
        open = !open
    }

    anchor.item: anchorItem
    anchor.rect.width: anchorItem.width
    anchor.rect.height: anchorItem.height + 8
    // Alineado con el borde derecho de la cápsula
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
            // Con MPD sonando se abre en su pestaña; si no, en MPRIS
            card.tab = Mpd.active ? "mpd" : "mpris"
            card.opacity = 1
            card.y = 0
        } else {
            open = false
            closedAt = Date.now()
            card.opacity = 0
            card.y = -8
        }
    }

    MediaCard {
        id: card
        width: parent.width
        active: root.visible
        opacity: 0
        y: -8

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y       { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }
}
