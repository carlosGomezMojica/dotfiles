import QtQuick

// Pestaña MPD del panel multimedia: álbumes en cover flow -> canciones del álbum ->
// reproducción (carátula con reflejo, tiempo y controles). Datos y acciones en Mpd.qml.
// Teclas (como el foco Dvorak de Hyprland): álbumes ←/→ o Ctrl+H/Ctrl+S, Enter abre;
// canciones ↑/↓ o Ctrl+N/Ctrl+T, Enter reproduce, Esc vuelve; reproduciendo, Espacio pausa.
// En el cover flow también dos dedos en el touchpad o la rueda.
FocusScope {
    id: root

    // El panel está abierto y esta pestaña a la vista
    property bool active: false
    // "albums" | "tracks" | "playing"
    property string view: "albums"
    // Álbum abierto en la vista de canciones y canción seleccionada con el teclado
    property var album: null
    property int selected: 0

    readonly property int coverSize: 112

    implicitHeight: content.implicitHeight

    // Al mostrarse: lo que suena, si hay algo; si no, la biblioteca
    function reset() {
        view = Mpd.active ? "playing" : "albums"
        if (Mpd.currentAlbum >= 0) flow.currentIndex = Mpd.currentAlbum
        root.forceActiveFocus()
    }

    function openAlbum(index) {
        album = Mpd.albums[index]
        // Seleccionar la que suena si es de este álbum; si no, la primera
        const playingIndex = album.tracks.findIndex(t => t.file === Mpd.current.file)
        selected = Mpd.active && playingIndex >= 0 ? playingIndex : 0
        view = "tracks"
        tracks.positionViewAtIndex(selected, ListView.Contain)
    }

    function moveSelection(delta) {
        const n = album?.tracks.length ?? 0
        if (n === 0) return
        selected = (selected + delta + n) % n
        tracks.positionViewAtIndex(selected, ListView.Contain)
    }

    // Un solo manejador para las tres vistas; también lo usa la cápsula (IndicatorBar)
    // cuando las teclas le llegan a ella en vez de al popup
    Keys.onPressed: event => { event.accepted = handleKey(event) }

    function handleKey(event) {
        const ctrl = event.modifiers & Qt.ControlModifier
        const k = event.key
        const left = k === Qt.Key_Left || (ctrl && k === Qt.Key_H)     // Ctrl+H: izquierda
        const right = k === Qt.Key_Right || (ctrl && k === Qt.Key_S)   // Ctrl+S: derecha
        const up = k === Qt.Key_Up || (ctrl && k === Qt.Key_N)         // Ctrl+N: arriba
        const down = k === Qt.Key_Down || (ctrl && k === Qt.Key_T)     // Ctrl+T: abajo
        const enter = k === Qt.Key_Return || k === Qt.Key_Enter

        if (view === "albums") {
            if (left) flow.decrementCurrentIndex()
            else if (right) flow.incrementCurrentIndex()
            else if (enter || down) openAlbum(flow.currentIndex)
            else return false
        } else if (view === "tracks") {
            if (up) moveSelection(-1)
            else if (down) moveSelection(1)
            else if (enter) play(selected)
            else if (k === Qt.Key_Escape || left) view = "albums"
            else return false
        } else {
            if (k === Qt.Key_Space) Mpd.toggle()
            else if (left) Mpd.prev()
            else if (right) Mpd.next()
            else if (k === Qt.Key_Escape || up) view = "albums"
            else return false
        }
        return true
    }

    function play(index) {
        Mpd.playAlbum(album, index)
        view = "playing"
    }

    onActiveChanged: if (active) reset()

    Binding {
        target: Mpd
        property: "watching"
        value: root.active
    }

    component Label: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 9
        font.letterSpacing: 1
    }

    // Píldora clicable (volver a los álbumes)
    component PillButton: StatusPill {
        id: button
        signal clicked()
        dotColor: Theme.aqua
        borderColor: buttonArea.containsMouse ? Theme.highlight : Theme.panelBorder

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    Column {
        id: content
        width: parent.width
        spacing: 12

        // --- Sin MPD o sin música ---
        Column {
            width: parent.width
            spacing: 8
            topPadding: 20
            bottomPadding: 20
            visible: !Mpd.available || Mpd.albums.length === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: String.fromCodePoint(0xF075A)   // nf-md-music
                color: Theme.surface
                font.family: Theme.font
                font.pixelSize: 48
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: !Mpd.available ? "MPD NO DISPONIBLE" : "SIN MÚSICA EN ~/Música"
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !Mpd.available
                text: "systemctl --user start mpd"
                font.letterSpacing: 0
                color: Theme.surface
            }
        }

        // --- Álbumes en cover flow ---
        Item {
            width: parent.width
            height: flow.height + albumInfo.height + 6
            visible: Mpd.available && Mpd.albums.length > 0 && root.view === "albums"

            PathView {
                id: flow

                readonly property real cx: width / 2
                readonly property real cy: root.coverSize / 2 + 4
                readonly property real gap: root.coverSize * 0.62
                readonly property real step: root.coverSize * 0.16
                // Número impar: tantas a la izquierda como a la derecha
                readonly property int slots: Math.max(1, Math.min(7, count % 2 ? count : count - 1))
                // Desplazamiento acumulado del touchpad
                property real swipe: 0

                width: parent.width
                height: root.coverSize + 46
                clip: true
                model: Mpd.albums
                pathItemCount: slots
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                highlightMoveDuration: 240
                snapMode: PathView.SnapOneItem

                // Dos dedos (horizontal o vertical): una carátula cada ~40 px; rueda: una por paso
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        let d = event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.pixelDelta.y
                        if (event.inverted) d = -d
                        if (d === 0) {
                            const a = event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y
                            if (a > 0) flow.decrementCurrentIndex()
                            else if (a < 0) flow.incrementCurrentIndex()
                            return
                        }
                        flow.swipe += d
                        while (flow.swipe >= 40) { flow.decrementCurrentIndex(); flow.swipe -= 40 }
                        while (flow.swipe <= -40) { flow.incrementCurrentIndex(); flow.swipe += 40 }
                    }
                }

                // Apiladas a los lados (giradas hacia el centro), la central de frente
                path: Path {
                    startX: flow.cx - flow.gap - (flow.slots / 2 - 1) * flow.step
                    startY: flow.cy
                    PathAttribute { name: "angle"; value: -60 }
                    PathAttribute { name: "depth"; value: 0 }
                    PathAttribute { name: "size"; value: 0.82 }

                    PathLine { x: flow.cx - flow.gap; y: flow.cy }
                    PathPercent { value: 0.5 - 1 / flow.slots }
                    PathAttribute { name: "angle"; value: -60 }
                    PathAttribute { name: "depth"; value: 50 }
                    PathAttribute { name: "size"; value: 0.82 }

                    PathLine { x: flow.cx; y: flow.cy }
                    PathPercent { value: 0.5 }
                    PathAttribute { name: "angle"; value: 0 }
                    PathAttribute { name: "depth"; value: 100 }
                    PathAttribute { name: "size"; value: 1 }

                    PathLine { x: flow.cx + flow.gap; y: flow.cy }
                    PathPercent { value: 0.5 + 1 / flow.slots }
                    PathAttribute { name: "angle"; value: 60 }
                    PathAttribute { name: "depth"; value: 50 }
                    PathAttribute { name: "size"; value: 0.82 }

                    PathLine { x: flow.cx + flow.gap + (flow.slots / 2 - 1) * flow.step; y: flow.cy }
                    PathAttribute { name: "angle"; value: 60 }
                    PathAttribute { name: "depth"; value: 0 }
                    PathAttribute { name: "size"; value: 0.82 }
                }

                delegate: Item {
                    id: card
                    required property var modelData
                    required property int index

                    width: root.coverSize
                    height: root.coverSize
                    z: PathView.depth ?? 0
                    scale: PathView.size ?? 1
                    // Giro y escala desde el borde inferior: todas apoyan en la misma línea
                    transformOrigin: Item.Bottom

                    transform: Rotation {
                        origin.x: card.width / 2
                        origin.y: card.height
                        axis { x: 0; y: 1; z: 0 }
                        angle: card.PathView.angle ?? 0
                    }

                    CoverArt {
                        anchors.fill: parent
                        radius: 8
                        source: card.modelData.cover ?? ""
                    }

                    // Reflejo
                    Item {
                        y: card.height
                        width: card.width
                        height: 40
                        clip: true

                        CoverArt {
                            width: card.width
                            height: card.height
                            radius: 8
                            source: card.modelData.cover ?? ""
                            transform: Scale { origin.y: card.height / 2; yScale: -1 }
                        }

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.alpha(Theme.bg, 0.5) }
                                GradientStop { position: 0.8; color: Theme.bg }
                            }
                        }
                    }

                    TapHandler {
                        onTapped: card.PathView.isCurrentItem ? root.openAlbum(card.index) : flow.currentIndex = card.index
                    }
                }
            }

            // Álbum y artista de la carátula central
            Column {
                id: albumInfo
                anchors.top: flow.bottom
                anchors.topMargin: 6
                width: parent.width
                spacing: 3

                readonly property var current: Mpd.albums[flow.currentIndex] ?? null

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: albumInfo.current?.album ?? ""
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: (albumInfo.current?.artist ?? "") + "  ·  " + (albumInfo.current?.tracks.length ?? 0) + " CANCIONES"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    elide: Text.ElideRight
                }
            }
        }

        // --- Canciones del álbum ---
        Column {
            width: parent.width
            spacing: 10
            visible: Mpd.available && root.view === "tracks" && root.album !== null

            Row {
                width: parent.width
                spacing: 10

                PillButton {
                    id: backToAlbums
                    anchors.verticalCenter: parent.verticalCenter
                    label: "‹ ÁLBUMES"
                    onClicked: root.view = "albums"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - backToAlbums.width - parent.spacing
                    text: root.album?.album ?? ""
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                }
            }

            ListView {
                id: tracks
                width: parent.width
                height: Math.min(contentHeight, 6 * (34 + spacing))
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.album?.tracks ?? []

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool playingThis: Mpd.active && Mpd.current.file === modelData.file

                    readonly property bool marked: rowHover.hovered || index === root.selected

                    width: tracks.width
                    height: 34
                    radius: 10
                    color: marked ? Qt.tint(Theme.bg, Qt.alpha(Theme.highlight, 0.08)) : Theme.bg
                    border.width: 1
                    border.color: marked ? Theme.highlight : playingThis ? Theme.aqua : Theme.panelBorder

                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.play(row.index) }

                    Text {
                        id: number
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
                        width: 18
                        text: row.modelData.track > 0 ? row.modelData.track : row.index + 1
                        color: row.playingThis ? Theme.aqua : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 9
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: number.right
                        anchors.leftMargin: 6
                        anchors.right: time.left
                        anchors.rightMargin: 8
                        text: row.modelData.title
                        color: row.playingThis ? Theme.aqua : Theme.text
                        font.family: Theme.font
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Text {
                        id: time
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        text: row.modelData.time
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 9
                    }
                }
            }
        }

        // --- Reproduciendo ---
        Column {
            width: parent.width
            spacing: 12
            visible: Mpd.available && root.view === "playing"

            PillButton {
                label: "‹ ÁLBUMES"
                onClicked: root.view = "albums"
            }

            ReflectedCover {
                anchors.horizontalCenter: parent.horizontalCenter
                size: 200
                source: Mpd.currentCover
                title: Mpd.current.title
                subtitle: [Mpd.current.album, Mpd.current.artist].filter(t => t !== "").join("  ·  ")
            }

            TimeBar {
                width: parent.width
                visible: Mpd.duration > 0
                position: Mpd.elapsed
                length: Mpd.duration
                canSeek: true
                onSeek: f => Mpd.seek(f)
            }

            PlayerControls {
                anchors.horizontalCenter: parent.horizontalCenter
                playing: Mpd.playing
                onPrevious: Mpd.prev()
                onToggle: Mpd.toggle()
                onNext: Mpd.next()
            }
        }
    }
}
