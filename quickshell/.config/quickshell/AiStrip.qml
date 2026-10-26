import QtQuick

// Uso de IA en la cápsula colapsada: 5 segmentos con el uso de la sesión, en naranja
Row {
    id: root
    spacing: 2

    readonly property int filled: Math.round(Ai.sessionPercent * 5)

    Repeater {
        model: 5

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
                color: seg.on ? Theme.warning : Theme.surface

                Behavior on height { NumberAnimation { duration: 150 } }
                Behavior on color  { ColorAnimation { duration: 150 } }
            }
        }
    }
}
