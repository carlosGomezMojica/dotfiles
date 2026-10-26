import QtQuick

// Red en la cápsula colapsada: 4 segmentos de señal
Row {
    id: root
    spacing: 2

    readonly property int filled: Net.online ? Math.max(1, Math.ceil(Net.signal * 4)) : 4
    readonly property color fillColor: Net.stateColor

    Repeater {
        model: 4

        delegate: Item {
            id: seg
            required property int index
            readonly property bool on: index < root.filled

            width: 4
            height: 9   // misma altura que la cápsula colapsada

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: seg.on ? 5 : 3
                radius: 0   // estilo cuadrado, como BatteryStrip
                color: seg.on ? root.fillColor : Theme.surface

                Behavior on height { NumberAnimation { duration: 150 } }
                Behavior on color  { ColorAnimation { duration: 150 } }
            }
        }
    }
}
