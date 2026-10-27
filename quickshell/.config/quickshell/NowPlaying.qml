import QtQuick

// Tarjeta "reproduciendo" para la pantalla de bloqueo: carátula, título y controles.
// MPD si está sonando (o en pausa); si no, el reproductor MPRIS de Media.qml.
Rectangle {
    id: root

    readonly property bool mpd: Mpd.active
    readonly property var player: Media.player
    readonly property bool hasMedia: mpd || Media.ready
    readonly property string title: mpd ? Mpd.current.title : Media.shownTitle
    readonly property string subtitle: mpd ? [Mpd.current.album, Mpd.current.artist].filter(t => t !== "").join("  ·  ")
                                           : [Media.shownArtist, Media.shownApp].filter(t => t !== "").join("  ·  ")
    readonly property string cover: mpd ? Mpd.currentCover : Media.cover
    readonly property bool playing: mpd ? Mpd.playing : (player?.isPlaying ?? false)

    visible: hasMedia
    width: 340
    height: 84
    radius: 18
    color: Qt.alpha(Theme.bg, 0.72)
    border.width: 1
    border.color: Theme.panelBorder

    CoverArt {
        id: art
        anchors.verticalCenter: parent.verticalCenter
        x: 14
        width: 56
        height: 56
        radius: 10
        source: root.cover
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: art.right
        anchors.leftMargin: 12
        anchors.right: controls.left
        // Los controles van escalados al 70 % desde su borde derecho: compensar el hueco
        anchors.rightMargin: 8 - controls.width * 0.3
        spacing: 3

        Text {
            width: parent.width
            text: root.title
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 12
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.subtitle.toUpperCase()
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 8
            font.letterSpacing: 1
            elide: Text.ElideRight
        }
    }

    PlayerControls {
        id: controls
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 4
        scale: 0.7
        transformOrigin: Item.Right
        spacing: 4
        playing: root.playing
        canPrev: root.mpd || (root.player?.canGoPrevious ?? false)
        canNext: root.mpd || (root.player?.canGoNext ?? false)
        onPrevious: root.mpd ? Mpd.prev() : root.player.previous()
        onToggle: root.mpd ? Mpd.toggle() : root.player.togglePlaying()
        onNext: root.mpd ? Mpd.next() : root.player.next()
    }
}
