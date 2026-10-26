import Quickshell
import QtQuick
import QtQuick.Effects

// Cápsula de indicadores arriba a la derecha.
// Colapsada: medidor del audio que suena (aqua). Al cambiar volumen o brillo se expande
// un momento con el nivel (rojo / amarillo), y al empezar a sonar algo, con la carátula,
// el título y la app (Media.qml). Al pasar el ratón muestra el volumen (rojo) y el brillo
// (amarillo); la rueda o dos dedos en el touchpad sobre cada uno lo ajustan.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; right: true }
    margins.right: 8
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // Ancho fijo suficiente para la alerta de música (la más ancha); la máscara limita el ratón
    implicitWidth: Math.max(300, bar.mediaWidth, bar.hoverWidth)
    implicitHeight: 8 + 52 + 8   // la alerta de música es la más alta

    // Solo el hotspot recibe el mouse; el resto deja pasar los clicks
    mask: Region { item: hotspot }

    // Expandida con el ratón encima (y un instante tras salir, sin parpadeos)
    readonly property bool expanded: hover.hovered || closeDelay.running
    // Aviso de volumen/brillo, solo si no está ya expandida
    readonly property bool showOsd: Levels.osd !== "" && !expanded
    readonly property bool showMedia: showOsd && Levels.osd === "media"
    readonly property bool showLevel: showOsd && !showMedia
    readonly property bool osdVolume: Levels.osd === "volume"
    readonly property real osdValue: osdVolume ? Levels.volume : Levels.brightness
    readonly property color osdColor: osdVolume ? (Levels.muted ? Theme.muted : Theme.error) : Theme.yellow
    // Ancho de la cápsula con la alerta de música: carátula pegada a la izquierda + texto
    readonly property real mediaWidth: 76 + 8 + mediaRow.implicitWidth + 18
    // Ratón encima mientras suena algo: carátula y título a la izquierda de volumen y brillo
    readonly property bool hoverMedia: expanded && Media.playing && Media.ready
    readonly property real hoverWidth: (hoverMedia ? 50 + 6 : 16) + hoverRow.implicitWidth + 16

    Timer { id: closeDelay; interval: 250 }

    Connections {
        target: hover
        function onHoveredChanged() { if (!hover.hovered) closeDelay.restart() }
    }

    // Zona de detección: estable, sin animaciones. No acepta la rueda, así que esta
    // llega a las zonas de volumen y brillo de debajo.
    Item {
        id: hotspot
        anchors.right: parent.right
        // Colapsada: franja delgada del ancho de la cápsula. Expandida: la cápsula entera.
        width: bar.expanded ? bar.hoverWidth : pill.collapsedWidth
        height: bar.expanded ? 8 + 34 : 8
        z: 1

        HoverHandler { id: hover }
    }

    Rectangle {
        id: pill
        readonly property bool open: bar.expanded || bar.showOsd
        readonly property real collapsedWidth: meter.implicitWidth + 20

        anchors.right: parent.right
        y: open ? 8 : 0
        width: bar.expanded ? bar.hoverWidth
             : bar.showMedia ? bar.mediaWidth
             : bar.showOsd ? osdRow.implicitWidth + 32
             : collapsedWidth
        height: bar.showMedia ? 52 : open ? 34 : 9   // la alerta de música es más alta
        radius: height / 2
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        Behavior on y      { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // Colapsada: medidor del audio
        LevelMeter {
            id: meter
            anchors.centerIn: parent
            opacity: pill.open ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // Aviso: icono, barra y porcentaje en rojo (volumen) o amarillo (brillo)
        Row {
            id: osdRow
            anchors.centerIn: parent
            spacing: 10
            opacity: bar.showLevel ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: bar.osdVolume ? Levels.volumeIcon(Levels.volume, Levels.muted) : Levels.brightnessIcon(Levels.brightness)
                color: bar.osdColor
                font.family: Theme.font
                font.pixelSize: 15
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 120
                height: 4
                radius: 2
                color: Theme.surface

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, bar.osdValue))
                    height: parent.height
                    radius: 2
                    color: bar.osdColor

                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                horizontalAlignment: Text.AlignRight
                text: bar.osdVolume && Levels.muted ? "MUTE" : Math.round(bar.osdValue * 100) + "%"
                color: bar.osdColor
                font.family: Theme.font
                font.pixelSize: 11
            }
        }

        // Lo que suena: la carátula ocupa el extremo izquierdo de la cápsula (recortada con
        // su misma curva y fundida hacia el fondo). En la alerta va con el título y
        // "ARTISTA · APP"; con el ratón encima, en tamaño proporcional junto a volumen y brillo.
        Item {
            id: coverBox
            x: 1
            y: 1
            width: bar.showMedia ? 76 : 50
            height: parent.height - 2
            opacity: bar.showMedia || bar.hoverMedia ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            // Contenido: la imagen, o una nota en aqua si no hay (o no carga). El recorte va
            // como layer.effect sobre el propio item visible: con una capa oculta como fuente,
            // la imagen que llega después no se repintaba
            Item {
                id: coverContent
                anchors.fill: parent
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: coverMask
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surface
                }

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -6
                    visible: cover.status !== Image.Ready
                    text: String.fromCodePoint(0xF075A)   // nf-md-music
                    color: Theme.aqua
                    font.family: Theme.font
                    font.pixelSize: 20
                }

                Image {
                    id: cover
                    anchors.fill: parent
                    source: Media.cover
                    sourceSize: Qt.size(152, 104)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }

            // Forma: curva de la cápsula a la izquierda, recta a la derecha
            Item {
                id: coverMask
                anchors.fill: parent
                layer.enabled: true
                visible: false

                Rectangle {
                    width: parent.width + parent.height
                    height: parent.height
                    radius: height / 2
                }
            }

            // Fundido del borde derecho hacia el fondo de la cápsula
            Rectangle {
                anchors.right: parent.right
                width: 30
                height: parent.height
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Theme.bg }
                }
            }
        }

        Row {
            id: mediaRow
            anchors.left: coverBox.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            opacity: bar.showMedia ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    width: Math.min(implicitWidth, 240)
                    text: Media.shownTitle
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    width: Math.min(implicitWidth, 240)
                    text: [Media.shownArtist, Media.shownApp].filter(t => t !== "").join("  ·  ").toUpperCase()
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    elide: Text.ElideRight
                }
            }

            // Punto aqua, como el medidor
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: Theme.aqua
            }
        }

        // Ratón encima: volumen (rojo) y brillo (amarillo). Cada zona tiene su rueda:
        // dos dedos en el touchpad o la rueda del ratón suben o bajan ese nivel.
        Row {
            id: hoverRow
            // Con música, a la derecha de la carátula; si no, centrada
            x: bar.hoverMedia ? coverBox.width + 6 : (parent.width - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            opacity: bar.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            // Título y, debajo, la app (solo mientras suena algo)
            Column {
                anchors.verticalCenter: parent.verticalCenter
                visible: bar.hoverMedia
                rightPadding: 6
                spacing: 1

                Text {
                    width: Math.min(implicitWidth, 150)
                    text: Media.shownTitle
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    width: Math.min(implicitWidth, 150)
                    text: Media.shownApp
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 8
                    font.letterSpacing: 1
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: bar.hoverMedia
                width: 1
                height: 14
                color: Theme.border
            }

            LevelZone {
                icon: Levels.volumeIcon(Levels.volume, Levels.muted)
                label: Levels.muted ? "MUTE" : Math.round(Levels.volume * 100) + "%"
                levelColor: Levels.muted ? Theme.muted : Theme.error
                onNudged: d => Levels.nudgeVolume(d)
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 14
                color: Theme.border
            }

            LevelZone {
                icon: Levels.brightnessIcon(Levels.brightness)
                label: Math.round(Levels.brightness * 100) + "%"
                levelColor: Theme.yellow
                onNudged: d => Levels.nudgeBrightness(d)
            }
        }
    }
}
