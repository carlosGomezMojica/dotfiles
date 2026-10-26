import QtQuick

// Controles del reproductor: ◇ anterior, ○ reproducir/pausa (aqua), ◇ siguiente
Row {
    id: root

    property bool playing: false
    property bool canPrev: true
    property bool canNext: true
    signal previous()
    signal toggle()
    signal next()

    spacing: 28

    // Anterior / siguiente: rombo con borde
    component DiamondButton: Item {
        id: diamond
        property string glyph
        property bool available: true
        signal clicked()

        width: 36
        height: 36

        Rectangle {
            anchors.centerIn: parent
            width: 24
            height: 24
            rotation: 45
            radius: 4
            color: area.containsMouse && diamond.available ? Qt.alpha(Theme.highlight, 0.08) : "transparent"
            border.width: 1
            border.color: area.containsMouse && diamond.available ? Theme.highlight : Theme.panelBorder

            Behavior on border.color { ColorAnimation { duration: 120 } }
        }

        Text {
            anchors.centerIn: parent
            text: diamond.glyph
            color: !diamond.available ? Theme.surface
                 : area.containsMouse ? Theme.highlight
                 : Theme.text
            font.family: Theme.font
            font.pixelSize: 14
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: diamond.available ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (diamond.available) diamond.clicked()
        }
    }

    DiamondButton {
        anchors.verticalCenter: parent.verticalCenter
        glyph: String.fromCodePoint(0xF04AE)   // nf-md-skip_previous
        available: root.canPrev
        onClicked: root.previous()
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        height: 44
        radius: 22
        color: playArea.containsMouse ? Qt.lighter(Theme.aqua, 1.1) : Theme.aqua

        Text {
            anchors.centerIn: parent
            text: String.fromCodePoint(root.playing ? 0xF03E4 : 0xF040A)   // nf-md-pause / play
            color: Theme.bg
            font.family: Theme.font
            font.pixelSize: 20
        }

        MouseArea {
            id: playArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggle()
        }
    }

    DiamondButton {
        anchors.verticalCenter: parent.verticalCenter
        glyph: String.fromCodePoint(0xF04AD)   // nf-md-skip_next
        available: root.canNext
        onClicked: root.next()
    }
}
