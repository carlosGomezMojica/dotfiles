import Quickshell.Hyprland
import QtQuick

Row {
    spacing: 4

    Repeater {
        model: 9

        delegate: Item {
            id: seg
            required property int index

            readonly property int wsId: index + 1
            readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
            readonly property bool occupied:
                Hyprland.workspaces.values.some(w => w.id === wsId)

            width: 10
            height: 9   // misma altura que la cápsula colapsada

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: seg.active ? 5 : 3
                radius: height / 2
                color: seg.active ? "#cba6f7"      // activo
                     : seg.occupied ? "#9399b2"    // ocupado
                     : "#313244"                   // vacío

                Behavior on height { NumberAnimation { duration: 150 } }
                Behavior on color  { ColorAnimation { duration: 150 } }
            }
        }
    }
}
