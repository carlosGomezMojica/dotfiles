import QtQuick
import QtQuick.Effects

// Carátula con esquinas redondeadas; si no hay imagen (o no carga), una nota en aqua.
// El recorte va como layer.effect sobre el item visible: con una capa oculta como
// fuente, la imagen que llega después no se repinta.
Item {
    id: root

    property string source: ""
    property real radius: 12

    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: mask
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: String.fromCodePoint(0xF075A)   // nf-md-music
        color: Theme.aqua
        font.family: Theme.font
        font.pixelSize: Math.round(Math.min(root.width, root.height) * 0.28)
    }

    Image {
        id: image
        anchors.fill: parent
        // Una ruta suelta (p. ej. el image-path de una notificación) se tomaría por un icono
        source: root.source.startsWith("/") ? "file://" + root.source : root.source
        sourceSize: Qt.size(400, 400)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
    }

    Item {
        id: mask
        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: root.radius
        }
    }
}
