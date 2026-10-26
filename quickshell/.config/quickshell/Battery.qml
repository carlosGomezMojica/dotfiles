import Quickshell.Services.UPower
import QtQuick

// Batería en la barra expandida: icono de pila + porcentaje
Row {
    id: root
    spacing: 6

    readonly property var device: UPower.displayDevice
    readonly property real level: device.percentage   // 0..1
    readonly property color fillColor: level <= 0.2 ? Theme.error   // batería baja
                                     : Theme.success
    readonly property bool charging: device.state === UPowerDeviceState.Charging

    signal clicked()

    visible: device.isLaptopBattery

    // Handlers (no ocupan sitio en el Row): abre el panel de batería
    TapHandler { onTapped: root.clicked() }
    HoverHandler { cursorShape: Qt.PointingHandCursor }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: body.width + cap.width
        height: body.height

        Rectangle {
            id: body
            width: 24
            height: 12
            radius: 3
            color: "transparent"
            border.width: 1
            border.color: Theme.muted

            Rectangle {
                x: 2
                y: 2
                width: (parent.width - 4) * root.level
                height: parent.height - 4
                radius: 1.5
                color: root.fillColor

                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }

                // Cargando: la punta del relleno (hasta donde va la carga) en naranja
                Rectangle {
                    anchors.right: parent.right
                    width: Math.min(parent.width, 4)
                    height: parent.height
                    radius: 1.5
                    color: Theme.warning
                    visible: root.charging
                }
            }
        }

        // Polo de la pila
        Rectangle {
            id: cap
            anchors.left: body.right
            anchors.verticalCenter: body.verticalCenter
            width: 2
            height: 5
            radius: 1
            color: Theme.muted
        }
    }

    Text {
        id: pct
        // Centra los dígitos (no la caja del texto, que incluye el espacio de descendentes)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: height / 2
            - (baselineOffset + digits.tightBoundingRect.y + digits.tightBoundingRect.height / 2)
        text: Math.round(root.level * 100) + "%"
        color: Theme.text
        font.pixelSize: 12
        font.bold: true

        TextMetrics {
            id: digits
            font: pct.font
            text: "0123456789"
        }
    }
}
