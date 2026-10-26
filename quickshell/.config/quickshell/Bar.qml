import Quickshell
import QtQuick

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors.top: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    implicitWidth: content.implicitWidth + 32
    implicitHeight: 34 + 8

    // Solo el hotspot recibe el mouse; el resto deja pasar los clicks
    mask: Region { item: hotspot }

    // Expandida al pasar el ratón o mientras el panel de batería está abierto
    readonly property bool expanded: hover.hovered || batteryPanel.open

    // Zona de detección: estable, sin animaciones
    Item {
        id: hotspot
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        // Colapsada: franja delgada del ancho de la cápsula. Expandida: cubre toda la cápsula.
        // (collapsedWidth solo cambia con el contenido, no se anima)
        width: bar.expanded ? parent.width : pill.collapsedWidth
        height: bar.expanded ? parent.height : 8
        // Por encima de la cápsula para que ningún hijo le robe el hover;
        // no acepta clics, así que estos llegan a los puntos y a la batería
        z: 1

        HoverHandler { id: hover }
    }

    Rectangle {
        id: pill
        readonly property bool expanded: bar.expanded
	readonly property real collapsedWidth: collapsedRow.implicitWidth + 20

        anchors.horizontalCenter: parent.horizontalCenter
        y: expanded ? 8 : 0
	width: expanded ? parent.width : collapsedWidth
	height: expanded ? 34 : 9
	radius: height / 2
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        Behavior on y      { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
	Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

	// Colapsada: barritas de workspaces + 10 segmentos de batería a la derecha
	Row {
		id: collapsedRow
		anchors.centerIn: parent
		spacing: 12
		opacity: pill.expanded ? 0 : 1
		Behavior on opacity { NumberAnimation { duration: 150 } }

		WorkspaceStrip {}
		BatteryStrip { anchors.verticalCenter: parent.verticalCenter }
	}

        // Expandida: puntos de workspaces + icono de batería con porcentaje a la derecha
        Row {
            id: content
            anchors.centerIn: parent
            spacing: 16
            opacity: pill.expanded ? 1 : 0
            // Oculta (opacidad 0) seguiría capturando ratón y tapando el hotspot
            enabled: pill.expanded
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Workspaces { anchors.verticalCenter: parent.verticalCenter }
            Battery {
                id: battery
                anchors.verticalCenter: parent.verticalCenter
                onClicked: batteryPanel.toggle()
            }
        }
    }

    BatteryPanel {
        id: batteryPanel
        anchorItem: battery
    }
}
