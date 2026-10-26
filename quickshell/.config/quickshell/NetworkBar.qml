import Quickshell
import QtQuick

// Cápsula de red arriba a la izquierda. Colapsada: 4 segmentos de señal.
// Al pasar el ratón muestra el nombre de la red; al pulsarla abre NetworkPanel.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true }
    margins.left: 8
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    implicitWidth: content.implicitWidth + 32
    implicitHeight: 34 + 8

    // Solo el hotspot recibe el mouse; el resto deja pasar los clicks
    mask: Region { item: hotspot }

    // Expandida al pasar el ratón o mientras el panel está abierto
    readonly property bool expanded: hover.hovered || panel.open

    // Zona de detección: estable, sin animaciones
    Item {
        id: hotspot
        // Colapsada: franja delgada del ancho de la cápsula. Expandida: toda la cápsula.
        width: bar.expanded ? parent.width : pill.collapsedWidth
        height: bar.expanded ? parent.height : 8
        z: 1

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: panel.toggle() }
    }

    Rectangle {
        id: pill
        readonly property bool expanded: bar.expanded
        readonly property real collapsedWidth: strip.implicitWidth + 20

        y: expanded ? 8 : 0
        width: expanded ? parent.width : collapsedWidth
        height: expanded ? 34 : 9
        radius: height / 2
        color: Theme.bg
        border.width: 1
        border.color: panel.open ? Theme.accent : Theme.border

        Behavior on y      { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        NetworkStrip {
            id: strip
            anchors.centerIn: parent
            opacity: pill.expanded ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 8
            opacity: pill.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Net.icon
                color: Net.stateColor
                font.family: Theme.font
                font.pixelSize: 15
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Net.wired ? "Cable" : Net.current?.name ?? "Sin red"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 11
            }
        }
    }

    NetworkPanel {
        id: panel
        anchorItem: pill
    }
}
