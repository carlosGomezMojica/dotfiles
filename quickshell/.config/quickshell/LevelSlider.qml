import QtQuick

// Slider de nivel (0..1): clic o arrastre para fijarlo, rueda para ±5 %
Item {
    id: root

    property real value: 0
    property color fillColor: Theme.accent
    signal moved(real value)

    implicitHeight: 18

    function setFromX(x) { moved(Math.max(0, Math.min(1, x / width))) }

    // Pista
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surface

        // Relleno
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: 3
            color: root.fillColor

            Behavior on width { NumberAnimation { duration: area.pressed ? 0 : 120; easing.type: Easing.OutCubic } }
        }
    }

    // Pomo
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: (root.width - width) * Math.max(0, Math.min(1, root.value))
        width: area.pressed || area.containsMouse ? 14 : 12
        height: width
        radius: width / 2
        color: Theme.text
        border.width: 2
        border.color: root.fillColor

        Behavior on x { NumberAnimation { duration: area.pressed ? 0 : 120; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.topMargin: -4
        anchors.bottomMargin: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFromX(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.setFromX(mouse.x) }
    }

    WheelHandler {
        onWheel: event => root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
