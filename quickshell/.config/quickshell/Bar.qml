import Quickshell
import QtQuick

PanelWindow {
    required property var modelData
    screen: modelData

    anchors.top: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    implicitWidth: content.implicitWidth + 32
    implicitHeight: 34 + 8

    // Solo el hotspot recibe el mouse; el resto deja pasar los clicks
    mask: Region { item: hotspot }

    // Zona de detección: estable, sin animaciones
    Item {
        id: hotspot
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        // Colapsada: franja delgada arriba. Expandida: cubre toda la cápsula.
        width: hover.hovered ? parent.width : 120
        height: hover.hovered ? parent.height : 8

        HoverHandler { id: hover }
    }

    Rectangle {
        id: pill
        readonly property bool expanded: hover.hovered
	readonly property real collapsedWidth: strip.implicitWidth + 20

        anchors.horizontalCenter: parent.horizontalCenter
        y: expanded ? 8 : 0
	width: expanded ? parent.width : collapsedWidth
	height: expanded ? 34 : 9
	radius: height / 2
        color: "#000000"
        border.width: 1
        border.color: "#1f1f1f"

        Behavior on y      { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
	Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

	WorkspaceStrip{
		id: strip
    		anchors.centerIn: parent
    		opacity: pill.expanded ? 0 : 1
    		Behavior on opacity { NumberAnimation { duration: 150 } }
	}

        Workspaces {
            id: content
            anchors.centerIn: parent
            opacity: pill.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }
}
