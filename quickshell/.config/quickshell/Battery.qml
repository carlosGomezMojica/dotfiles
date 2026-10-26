import Quickshell.Services.UPower
import QtQuick

// Batería en la barra expandida: icono de pila + porcentaje
Row {
    id: root
    spacing: 6

    readonly property var device: UPower.displayDevice
    readonly property real level: device.percentage   // 0..1
    readonly property color fillColor: level <= 0.2 ? "#f38ba8"   // batería baja
                                     : "#a6e3a1"

    visible: device.isLaptopBattery

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
            border.color: "#9399b2"

            Rectangle {
                x: 2
                y: 2
                width: (parent.width - 4) * root.level
                height: parent.height - 4
                radius: 1.5
                color: root.fillColor

                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
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
            color: "#9399b2"
        }
    }

    Text {
        id: pct
        // Centra los dígitos (no la caja del texto, que incluye el espacio de descendentes)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: height / 2
            - (baselineOffset + digits.tightBoundingRect.y + digits.tightBoundingRect.height / 2)
        text: Math.round(root.level * 100) + "%"
        color: "#cdd6f4"
        font.pixelSize: 12
        font.bold: true

        TextMetrics {
            id: digits
            font: pct.font
            text: "0123456789"
        }
    }
}
