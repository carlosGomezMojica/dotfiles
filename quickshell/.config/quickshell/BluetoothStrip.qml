import QtQuick

// Bluetooth en la cápsula colapsada: una barrita como las de WorkspaceStrip
Item {
    id: root

    readonly property bool active: Bt.connected.length > 0

    width: 10
    height: 9   // misma altura que la cápsula colapsada

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: root.active ? 5 : 3
        radius: height / 2
        color: Bt.stateColor

        Behavior on height { NumberAnimation { duration: 150 } }
        Behavior on color  { ColorAnimation { duration: 150 } }
    }
}
