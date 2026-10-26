import Quickshell
import QtQuick

// Cápsula de red arriba a la izquierda. Colapsada: 4 segmentos de señal y la barrita de bluetooth.
// Al pasar el ratón muestra reloj | red | bluetooth; cada zona abre su panel al pulsarla
// (CalendarPanel, NetworkPanel y BluetoothPanel).
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

    // Expandida al pasar el ratón o mientras un panel está abierto
    readonly property bool expanded: hover.hovered || panel.open || calendarPanel.open || btPanel.open

    SystemClock {
        id: clockSource
        precision: SystemClock.Minutes
    }

    // Zona de detección: estable, sin animaciones
    Item {
        id: hotspot
        // Colapsada: franja delgada del ancho de la cápsula. Expandida: toda la cápsula.
        width: bar.expanded ? parent.width : pill.collapsedWidth
        height: bar.expanded ? parent.height : 8
        z: 1

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        // El hotspot tapa la cápsula: el clic se reparte según los separadores
        TapHandler {
            onTapped: eventPoint => {
                const x = eventPoint.position.x
                if (x < separator.mapToItem(hotspot, 0, 0).x) calendarPanel.toggle()
                else if (x < btSeparator.mapToItem(hotspot, 0, 0).x) panel.toggle()
                else btPanel.toggle()
            }
        }
    }

    Rectangle {
        id: pill
        readonly property bool expanded: bar.expanded
        readonly property real collapsedWidth: strips.implicitWidth + 20

        y: expanded ? 8 : 0
        width: expanded ? parent.width : collapsedWidth
        height: expanded ? 34 : 9
        radius: height / 2
        color: Theme.bg
        border.width: 1
        border.color: panel.open || calendarPanel.open || btPanel.open ? Theme.accent : Theme.border

        Behavior on y      { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            id: strips
            anchors.centerIn: parent
            spacing: 8
            opacity: pill.expanded ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }

            NetworkStrip {}
            BluetoothStrip {}
        }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 8
            opacity: pill.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(clockSource.date, "HH:mm")
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 11
            }

            Rectangle {
                id: separator
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 14
                color: Theme.border
            }

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

            Rectangle {
                id: btSeparator
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 14
                color: Theme.border
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Bt.icon
                color: Bt.stateColor
                font.family: Theme.font
                font.pixelSize: 15
            }

            // Dispositivo conectado (o cuántos hay)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
                text: Bt.summary
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

    CalendarPanel {
        id: calendarPanel
        anchorItem: pill
    }

    BluetoothPanel {
        id: btPanel
        anchorItem: pill
    }
}
