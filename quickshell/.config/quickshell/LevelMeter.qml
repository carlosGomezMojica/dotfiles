import QtQuick

// Indicadores en la cápsula colapsada: barra horizontal que se ilumina con el audio que suena.
// Se llena de derecha a izquierda, desde el borde de la pantalla.
Row {
    id: root
    spacing: 2

    readonly property int count: 12
    readonly property int lit: Math.round(Levels.peak * count)

    Repeater {
        model: root.count

        delegate: Item {
            id: seg
            required property int index
            // Los últimos (los de la derecha) se encienden primero
            readonly property bool on: index >= root.count - root.lit

            width: 4
            height: 9   // misma altura que la cápsula colapsada

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: seg.on ? 5 : 3
                radius: 0   // estilo cuadrado, como BatteryStrip
                color: seg.on ? Theme.aqua : Theme.surface

                Behavior on height { NumberAnimation { duration: 80 } }
                Behavior on color  { ColorAnimation { duration: 80 } }
            }
        }
    }
}
