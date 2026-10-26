import QtQuick

// Tiempo de reproducción: actual, barra (clic para saltar) y total
Item {
    id: root

    property real position: 0   // segundos
    property real length: 0     // segundos
    property bool canSeek: false
    signal seek(real fraction)

    implicitHeight: 14

    // Segundos -> "m:ss" (o "h:mm:ss")
    function format(sec) {
        const t = Math.max(0, Math.floor(sec || 0))
        const h = Math.floor(t / 3600), m = Math.floor(t % 3600 / 60), s = t % 60
        const ss = (s < 10 ? "0" : "") + s
        return h > 0 ? h + ":" + (m < 10 ? "0" : "") + m + ":" + ss : m + ":" + ss
    }

    component Label: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 9
        font.letterSpacing: 1
    }

    Label {
        id: elapsed
        anchors.verticalCenter: parent.verticalCenter
        text: root.format(root.position)
    }

    Label {
        id: total
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        text: root.format(root.length)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: elapsed.right
        anchors.leftMargin: 10
        anchors.right: total.left
        anchors.rightMargin: 10
        height: 4
        radius: 2
        color: Theme.surface

        Rectangle {
            width: parent.width * (root.length > 0 ? Math.max(0, Math.min(1, root.position / root.length)) : 0)
            height: parent.height
            radius: 2
            color: Theme.aqua

            Behavior on width { NumberAnimation { duration: 300 } }
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -6
            anchors.bottomMargin: -6
            enabled: root.canSeek
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: mouse => root.seek(Math.max(0, Math.min(1, mouse.x / width)))
        }
    }
}
