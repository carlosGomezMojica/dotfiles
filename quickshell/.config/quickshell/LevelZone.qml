import QtQuick

// Icono + porcentaje de la cápsula de indicadores, con su propia zona de rueda
Item {
    id: zone
    property string icon
    property string label
    property color levelColor
    signal nudged(real delta)

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: zoneRow.implicitWidth + 12
    implicitHeight: 34

    Row {
        id: zoneRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: zone.icon
            color: zone.levelColor
            font.family: Theme.font
            font.pixelSize: 15
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: zone.label
            color: zone.levelColor
            font.family: Theme.font
            font.pixelSize: 11
        }
    }

    // Touchpad: avance continuo según los píxeles deslizados (~25 % cada 100 px).
    // Rueda: 5 % por paso. Deslizar hacia arriba siempre sube, también con desplazamiento natural.
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            let d = event.pixelDelta.y !== 0 ? event.pixelDelta.y / 400
                                             : event.angleDelta.y / 120 * 0.05
            if (event.inverted) d = -d
            zone.nudged(d)
        }
    }
}
