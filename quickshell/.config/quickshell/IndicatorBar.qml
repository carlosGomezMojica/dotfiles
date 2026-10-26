import Quickshell
import QtQuick

// Cápsula de indicadores arriba a la derecha.
// Colapsada: medidor del audio que suena (aqua). Al cambiar volumen o brillo se expande
// un momento con el nivel (rojo / amarillo). Al pasar el ratón despliega IndicatorCard
// con los sliders. Cápsula y tarjeta en una sola ventana: el hover no salta entre ventanas.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; right: true }
    margins.right: 8
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    implicitWidth: card.implicitWidth
    implicitHeight: cardTop + card.implicitHeight + 8

    // Solo el hotspot recibe el mouse; el resto deja pasar los clicks
    mask: Region { item: hotspot }

    readonly property int cardTop: 8 + 34 + 8
    // Expandida con el ratón encima (y un instante tras salir, sin parpadeos)
    readonly property bool expanded: hover.hovered || closeDelay.running
    // Aviso de volumen/brillo, solo si no está ya expandida
    readonly property bool showOsd: Levels.osd !== "" && !expanded
    readonly property bool osdVolume: Levels.osd === "volume"
    readonly property real osdValue: osdVolume ? Levels.volume : Levels.brightness
    readonly property color osdColor: osdVolume ? (Levels.muted ? Theme.muted : Theme.error) : Theme.yellow

    Timer { id: closeDelay; interval: 250 }

    Connections {
        target: hover
        function onHoveredChanged() { if (!hover.hovered) closeDelay.restart() }
    }

    // Zona de detección: estable, sin animaciones. No acepta clics, así que estos
    // llegan a los sliders de la tarjeta.
    Item {
        id: hotspot
        anchors.right: parent.right
        // Colapsada: franja delgada del ancho de la cápsula. Expandida: cápsula + tarjeta.
        width: bar.expanded ? parent.width : pill.collapsedWidth
        height: bar.expanded ? parent.height : 8
        z: 1

        HoverHandler { id: hover }
    }

    Rectangle {
        id: pill
        readonly property bool open: bar.expanded || bar.showOsd
        readonly property real collapsedWidth: meter.implicitWidth + 20

        anchors.right: parent.right
        y: open ? 8 : 0
        width: bar.expanded ? hoverRow.implicitWidth + 32
             : bar.showOsd ? osdRow.implicitWidth + 32
             : collapsedWidth
        height: open ? 34 : 9
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
            opacity: bar.showOsd ? 1 : 0
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

        // Ratón encima: resumen de volumen y brillo
        Row {
            id: hoverRow
            anchors.centerIn: parent
            spacing: 8
            opacity: bar.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Levels.volumeIcon(Levels.volume, Levels.muted)
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 15
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Levels.muted ? "MUTE" : Math.round(Levels.volume * 100) + "%"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 11
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 14
                color: Theme.border
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Levels.brightnessIcon(Levels.brightness)
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 15
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Levels.brightness * 100) + "%"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 11
            }
        }
    }

    IndicatorCard {
        id: card
        width: implicitWidth
        anchors.right: parent.right
        y: bar.expanded ? bar.cardTop : bar.cardTop - 8
        opacity: bar.expanded ? 1 : 0
        visible: opacity > 0
        // Oculta no debe recibir clics
        enabled: bar.expanded

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y       { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }
}
