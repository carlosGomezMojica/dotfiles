import QtQuick

// Tarjeta del panel multimedia (al pulsar la cápsula de indicadores): pestañas MPRIS
// (lo que suene en cualquier app) y MPD (biblioteca local, MpdView); debajo, volumen y brillo
Rectangle {
    id: root

    // "mpris" | "mpd"
    property string tab: "mpris"
    // El panel la activa mientras está abierto (refrescar la posición, foco del teclado)
    property bool active: false

    readonly property var player: Media.player
    readonly property bool hasPlayer: player !== null && (player.trackTitle ?? "") !== ""
    readonly property string title: Media.ready ? Media.shownTitle : (player?.trackTitle ?? "")
    readonly property string artist: Media.ready ? Media.shownArtist : (player?.trackArtist ?? "")

    readonly property int padding: 20

    // Teclas reenviadas desde la cápsula: solo las usa la pestaña MPD
    function handleKey(event) { return tab === "mpd" && mpdView.handleKey(event) }

    implicitWidth: 320
    implicitHeight: column.implicitHeight + padding * 2
    radius: 16
    color: Theme.bg
    border.width: 1
    border.color: Theme.panelBorder

    // MPRIS no avisa de la posición: pedirla cada segundo mientras se ve y suena algo
    Timer {
        interval: 1000
        repeat: true
        running: root.active && root.tab === "mpris" && root.hasPlayer && (root.player?.isPlaying ?? false)
        onTriggered: root.player.positionChanged()
    }

    component Label: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 9
        font.letterSpacing: 1
    }

    // Pestaña: activa con borde y texto en acento y fondo tintado (como los perfiles de batería)
    component TabButton: Rectangle {
        id: tabButton
        property string label
        property bool active
        signal clicked()

        height: 26
        radius: height / 2
        color: active ? Qt.alpha(Theme.accent, 0.08) : "transparent"
        border.width: 1
        border.color: active ? Theme.accent : tabArea.containsMouse ? Theme.highlight : Theme.panelBorder

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: tabButton.label
            color: tabButton.active ? Theme.accent : Theme.muted
            font.family: Theme.font
            font.pixelSize: 9
            font.letterSpacing: 1.5
        }

        MouseArea {
            id: tabArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tabButton.clicked()
        }
    }

    // Recuadro de nivel: slider + casilla con el porcentaje
    component LevelBox: Rectangle {
        id: box
        property real value
        property string label
        property color levelColor
        signal moved(real value)
        signal labelClicked()

        width: parent.width
        height: 42
        radius: 12
        color: "transparent"
        border.width: 1
        border.color: box.levelColor

        LevelSlider {
            anchors.verticalCenter: parent.verticalCenter
            x: 14
            width: parent.width - 14 - valueBox.width - 22
            value: box.value
            fillColor: box.levelColor
            onMoved: v => box.moved(v)
        }

        Rectangle {
            id: valueBox
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 8
            width: 52
            height: 26
            radius: 8
            color: valueArea.containsMouse ? Qt.alpha(box.levelColor, 0.12) : "transparent"
            border.width: 1
            border.color: box.levelColor

            Text {
                anchors.centerIn: parent
                text: box.label
                color: box.levelColor
                font.family: Theme.font
                font.pixelSize: 11
            }

            MouseArea {
                id: valueArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: box.labelClicked()
            }
        }
    }

    Column {
        id: column
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 14

        // Bloque multimedia
        Rectangle {
            width: parent.width
            height: media.implicitHeight + 32
            radius: 14
            color: "transparent"
            border.width: 1
            border.color: Theme.panelBorder

            Column {
                id: media
                x: 16
                y: 16
                width: parent.width - 32
                spacing: 14

                Row {
                    width: parent.width
                    spacing: 8

                    TabButton {
                        width: (parent.width - parent.spacing) / 2
                        label: "MPRIS"
                        active: root.tab === "mpris"
                        onClicked: root.tab = "mpris"
                    }

                    TabButton {
                        width: (parent.width - parent.spacing) / 2
                        label: "MPD"
                        active: root.tab === "mpd"
                        onClicked: root.tab = "mpd"
                    }
                }

                // MPRIS: carátula con reflejo, tiempo y controles
                Column {
                    width: parent.width
                    spacing: 12
                    visible: root.tab === "mpris" && root.hasPlayer

                    ReflectedCover {
                        anchors.horizontalCenter: parent.horizontalCenter
                        size: 200
                        source: Media.cover
                        title: root.title
                        subtitle: root.artist
                    }

                    TimeBar {
                        width: parent.width
                        visible: length > 0
                        position: root.player?.position ?? 0
                        length: root.player?.length ?? 0
                        canSeek: root.player?.canSeek ?? false
                        onSeek: f => {
                            root.player.position = f * length
                            root.player.positionChanged()
                        }
                    }

                    PlayerControls {
                        anchors.horizontalCenter: parent.horizontalCenter
                        playing: root.player?.isPlaying ?? false
                        canPrev: root.player?.canGoPrevious ?? false
                        canNext: root.player?.canGoNext ?? false
                        onPrevious: root.player.previous()
                        onToggle: root.player.togglePlaying()
                        onNext: root.player.next()
                    }
                }

                // MPRIS sin nada sonando
                Column {
                    width: parent.width
                    spacing: 8
                    topPadding: 20
                    bottomPadding: 20
                    visible: root.tab === "mpris" && !root.hasPlayer

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: String.fromCodePoint(0xF075A)   // nf-md-music
                        color: Theme.surface
                        font.family: Theme.font
                        font.pixelSize: 48
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "NADA SONANDO"
                    }
                }

                // MPD: biblioteca local
                MpdView {
                    id: mpdView
                    width: parent.width
                    visible: root.tab === "mpd"
                    active: root.active && root.tab === "mpd"
                }
            }
        }

        // Volumen (clic en el porcentaje: silenciar)
        LevelBox {
            value: Levels.volume
            label: Levels.muted ? "MUTE" : Math.round(Levels.volume * 100) + "%"
            levelColor: Levels.muted ? Theme.muted : Theme.error
            onMoved: v => Levels.setVolume(v)
            onLabelClicked: Levels.toggleMute()
        }

        // Brillo
        LevelBox {
            value: Levels.brightness
            label: Math.round(Levels.brightness * 100) + "%"
            levelColor: Theme.yellow
            onMoved: v => Levels.setBrightness(v)
        }
    }
}
