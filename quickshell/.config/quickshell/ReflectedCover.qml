import QtQuick

// Carátula estilo iPod: de frente, con su reflejo fundido hacia el fondo y el título
// y un subtítulo centrados encima del reflejo
Item {
    id: root

    property string source: ""
    property string title: ""
    property string subtitle: ""
    property real size: 200
    property real reflectionHeight: 64

    implicitWidth: size
    implicitHeight: size + 2 + reflectionHeight

    CoverArt {
        width: root.size
        height: root.size
        source: root.source
    }

    Item {
        y: root.size + 2
        width: root.size
        height: root.reflectionHeight
        clip: true

        CoverArt {
            width: root.size
            height: root.size
            source: root.source
            transform: Scale { origin.y: root.size / 2; yScale: -1 }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha(Theme.bg, 0.55) }
                GradientStop { position: 0.85; color: Theme.bg }
            }
        }

        Column {
            y: 10
            width: parent.width
            spacing: 3

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.title
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
                text: root.subtitle
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }
}
