import QtQuick

// Píldora con borde, texto en mayúsculas y punto de estado (estilo "STABLE ●")
Rectangle {
    id: root

    property string label: ""
    property color dotColor: Theme.success
    property color borderColor: Theme.panelBorder
    property color textColor: Theme.text

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 22
    radius: height / 2
    color: "transparent"
    border.width: 1
    border.color: root.borderColor

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.textColor
            font.family: Theme.font
            font.pixelSize: 9
            font.letterSpacing: 1
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: root.dotColor

            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
}
