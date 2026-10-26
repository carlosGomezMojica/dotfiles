import QtQuick

// Tarjeta de la cápsula de indicadores: sliders de volumen y brillo
Rectangle {
    id: root

    readonly property int padding: 20

    implicitWidth: 300
    implicitHeight: column.implicitHeight + padding * 2
    radius: 16
    color: Theme.bg
    border.width: 1
    border.color: Theme.panelBorder

    component Heading: Text {
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 11
        font.letterSpacing: 1.5
    }

    // Sección: título + píldora con el porcentaje, e icono + slider
    component Level: Column {
        id: level
        property string title
        property string pill
        property color levelColor
        property string icon
        property real value
        signal moved(real value)
        signal iconClicked()

        width: parent.width
        spacing: 12

        Item {
            width: parent.width
            height: pillItem.height

            Heading {
                anchors.verticalCenter: parent.verticalCenter
                text: level.title
            }

            StatusPill {
                id: pillItem
                anchors.right: parent.right
                label: level.pill
                dotColor: level.levelColor
            }
        }

        Row {
            width: parent.width
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                text: level.icon
                color: iconArea.containsMouse ? Theme.text : level.levelColor
                font.family: Theme.font
                font.pixelSize: 18

                MouseArea {
                    id: iconArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: level.iconClicked()
                }
            }

            LevelSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 32
                value: level.value
                fillColor: level.levelColor
                onMoved: v => level.moved(v)
            }
        }
    }

    Column {
        id: column
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 20

        // Clic en el icono: silenciar
        Level {
            title: "01  VOLUMEN"
            pill: Levels.muted ? "SILENCIO" : Math.round(Levels.volume * 100) + "%"
            levelColor: Levels.muted ? Theme.muted : Theme.error
            icon: Levels.volumeIcon(Levels.volume, Levels.muted)
            value: Levels.volume
            onMoved: v => Levels.setVolume(v)
            onIconClicked: Levels.toggleMute()
        }

        Level {
            title: "02  BRILLO"
            pill: Math.round(Levels.brightness * 100) + "%"
            levelColor: Theme.yellow
            icon: Levels.brightnessIcon(Levels.brightness)
            value: Levels.brightness
            onMoved: v => Levels.setBrightness(v)
        }
    }
}
