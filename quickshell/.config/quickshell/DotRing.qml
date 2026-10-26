import QtQuick

// Anillo de puntos: los primeros round(level * count) se encienden,
// empezando arriba y en sentido horario
Item {
    id: root

    property real level: 0        // 0..1
    property int count: 48
    property real dotSize: 4
    property color onColor: Theme.success
    property color offColor: Theme.surface

    readonly property int lit: Math.round(level * count)
    readonly property real ringRadius: Math.min(width, height) / 2 - dotSize

    Repeater {
        model: root.count

        delegate: Rectangle {
            required property int index
            readonly property real angle: index / root.count * 2 * Math.PI - Math.PI / 2
            readonly property bool on: index < root.lit

            width: on ? root.dotSize : root.dotSize * 0.7
            height: width
            radius: width / 2
            x: root.width / 2 + Math.cos(angle) * root.ringRadius - width / 2
            y: root.height / 2 + Math.sin(angle) * root.ringRadius - height / 2
            color: on ? root.onColor : root.offColor

            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on width { NumberAnimation { duration: 200 } }
        }
    }
}
