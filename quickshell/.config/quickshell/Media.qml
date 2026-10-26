pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// Lo que suena ahora (MPRIS). Al empezar una pista o reanudar la reproducción,
// la cápsula de indicadores muestra una alerta con carátula, título y app.
//
// Los navegadores envían el título al instante pero la carátula segundos después (la
// descargan y la guardan como archivo local). Para no mostrar nada a medias, una pista
// solo está lista (`ready`) cuando su carátula nueva ha cargado, o tras `artTimeout`
// si el reproductor no envía ninguna.
Singleton {
    id: root

    // El último que empezó a sonar (si sigue sonando); si no, cualquiera que suene; si no, el primero
    readonly property var player: (latest?.isPlaying ? latest : null)
        ?? Mpris.players.values.find(p => p.isPlaying) ?? latest ?? Mpris.players.values[0] ?? null
    property var latest: null

    // Recordar qué reproductor arrancó más recientemente (p. ej. MPD mientras suena el navegador)
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            function onIsPlayingChanged() { if (modelData.isPlaying) root.latest = modelData }
        }
    }

    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    // Sin el sufijo de conexión que añaden algunos puentes ("MPD on 127.0.0.1:6600" -> "MPD")
    readonly property string app: (player?.identity ?? "").replace(/ on \S+$/i, "").toUpperCase()
    readonly property string art: player?.trackArtUrl ?? ""
    readonly property bool playing: player?.isPlaying ?? false

    // Pista con sus datos completos. La interfaz usa estos (no title/art), que solo
    // cambian todos juntos cuando la carátula nueva está lista
    readonly property bool ready: title !== "" && readyKey === key
    property string cover: ""
    property string shownTitle: ""
    property string shownArtist: ""
    property string shownApp: ""

    readonly property int artTimeout: 2000
    readonly property string key: title + "\u0000" + artist
    property string readyKey: ""
    property string pendingKey: ""
    // Carátula (URL original) de la pista anterior: la nueva tiene que ser distinta
    property string previousCover: ""
    // URL original de la carátula mostrada (`cover` apunta a nuestra copia)
    property string sourceArt: ""
    // La alerta se muestra al quedar lista la pista (si empezó a sonar después de arrancar)
    property bool alertWanted: false

    function begin() {
        pendingKey = key
        previousCover = sourceArt
        alertWanted = !settle.running && playing
        waitLimit.restart()
        check()
    }

    // ¿Ya cargó una carátula nueva para la pista pendiente?
    function check() {
        if (pendingKey === "" || pendingKey !== key) return
        if (preload.status === Image.Ready && art !== "" && art !== previousCover) commit(art)
    }

    // Datos de la pista que se está confirmando (mientras se copia su carátula)
    property var committing: null

    function commit(url) {
        waitLimit.stop()
        committing = { url: url, title: title, artist: artist, app: app, key: pendingKey, alert: alertWanted }
        pendingKey = ""
        alertWanted = false
        stash(url)
    }

    function finish(local) {
        const c = committing
        committing = null
        if (!c) return
        cover = local
        sourceArt = c.url
        shownTitle = c.title
        shownArtist = c.artist
        shownApp = c.app
        readyKey = c.key
        if (c.alert && playing) Levels.show("media", 4000)
    }

    // Los reproductores borran la carátula anterior al escribir la nueva (mpd-mpris en
    // /tmp/mpd_mpris, Zen en ~/.config/zen/firefox-mpris), y las vistas la piden a otro
    // tamaño que la precarga, así que vuelven a leer el archivo: si ya no existe, sale la
    // nota. Se copia a una carpeta propia y se muestra la copia.
    readonly property string stashDir: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-media"
    property int stashCount: 0

    function stash(url) {
        if (!url.startsWith("file://")) { finish(url); return }
        if (copier.running) { copier.queued = true; return }
        stashCount++
        copier.dest = stashDir + "/cover-" + stashCount
        copier.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && cp -f "$1" "$2" && rm -f "$3"', "sh",
                          decodeURIComponent(url.slice(7)), copier.dest, stashDir + "/cover-" + (stashCount - 2)]
        copier.running = true
    }

    Process {
        id: copier
        property string dest: ""
        property bool queued: false
        onExited: code => {
            if (queued) {
                // Llegó otra carátula mientras se copiaba: copiar la última
                queued = false
                root.stash(root.committing?.url ?? "")
                return
            }
            root.finish(code === 0 ? "file://" + dest : (root.committing?.url ?? ""))
        }
    }

    // Carga la carátula fuera de pantalla para saber cuándo está disponible
    Image {
        id: preload
        source: root.art
        asynchronous: true
        sourceSize: Qt.size(152, 104)
        onStatusChanged: {
            if (status !== Image.Ready) return
            if (root.pendingKey !== "") root.check()
            // La misma pista cambió de carátula más tarde: actualizarla sin otra alerta
            else if (root.ready && root.art !== "" && root.art !== root.sourceArt && root.committing === null) {
                root.committing = { url: root.art, title: root.shownTitle, artist: root.shownArtist,
                                    app: root.shownApp, key: root.readyKey, alert: false }
                root.stash(root.art)
            }
        }
    }

    // Sin carátula a tiempo: mostrar la pista igualmente (con la nota de respaldo)
    Timer {
        id: waitLimit
        interval: root.artTimeout
        onTriggered: {
            if (root.pendingKey === "" || root.pendingKey !== root.key) return
            root.commit(preload.status === Image.Ready && root.art !== root.previousCover ? root.art : "")
        }
    }

    // Los metadatos llegan a trozos (título, luego artista): esperar a que se asienten
    Timer {
        id: debounce
        interval: 300
        onTriggered: if (root.title !== "" && root.key !== root.readyKey && root.key !== root.pendingKey) root.begin()
    }

    // Al arrancar la shell no es una pista nueva (no hay alerta)
    Timer {
        id: settle
        interval: 1500
        running: true
    }

    onKeyChanged: debounce.restart()

    // Reanudar (pausa -> reproduciendo) también avisa, aunque sea la misma pista
    onPlayingChanged: {
        if (!playing || settle.running) return
        if (ready) Levels.show("media", 4000)
        else if (pendingKey !== "") alertWanted = true
    }
}
