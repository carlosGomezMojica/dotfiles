import Quickshell.Services.UPower
import QtQuick

// Batería en la barra colapsada: 10 segmentos, cada uno representa un 10%
Row {
    id: root
    spacing: 2

    readonly property var device: UPower.displayDevice
    readonly property real level: device.percentage   // 0..1
    readonly property int filled: Math.round(level * 10)
    readonly property color fillColor: level <= 0.2 ? Theme.error   // batería baja
                                     : Theme.success
    readonly property bool charging: device.state === UPowerDeviceState.Charging

    visible: device.isLaptopBattery

    Repeater {
        model: 10

        delegate: Item {
            id: seg
            required property int index
            readonly property bool on: index < root.filled
            // Cargando: el segmento hasta donde va la carga, en naranja
            readonly property bool lead: root.charging && index === root.filled - 1

            width: 4
            height: 9   // misma altura que la cápsula colapsada

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: seg.on ? 5 : 3
                radius: 0   // estilo cuadrado
                color: seg.lead ? Theme.warning : seg.on ? root.fillColor : Theme.surface

                Behavior on height { NumberAnimation { duration: 150 } }
                Behavior on color  { ColorAnimation { duration: 150 } }
            }
        }
    }
}
