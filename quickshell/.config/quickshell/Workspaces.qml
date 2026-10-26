import Quickshell.Hyprland
import QtQuick

Row {
	spacing: 6

	Repeater {
		model: 9
		delegate: Rectangle {
			id: dot
			required property int index

			readonly property int wsId: index + 1
			readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
			readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)
			width : active ? 28 : 10
			height: 10
			radius: height / 2
			color: active ? Theme.accent
			     : occupied ? Theme.muted
			     : Theme.surface
			Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic}}
			Behavior on color { ColorAnimation { duration: 150} }

			MouseArea {
				anchors.fill: parent
				anchors.margins: -4
				cursorShape: Qt.PointingHandCursor
				onClicked: Hyprland.dispatch("hl.dsp.focus({workspace = " + dot.wsId + "})")	
			}
		}
	}
}
