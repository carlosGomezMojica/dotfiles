pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Biblioteca y estado de MPD a través de mpc (pestaña MPD del panel multimedia).
// `mpc idleloop` avisa de los cambios; las carátulas salen de cover/folder/front.(jpg|png)
// en la carpeta del álbum o, si no hay, de la imagen incrustada (ffmpeg -> ~/.cache/mpd-covers).
Singleton {
    id: root

    readonly property string musicDir: Quickshell.env("HOME") + "/Música"

    // mpc responde (MPD en marcha)
    property bool available: false
    // [{ key, album, artist, dir, cover, tracks: [{ title, track, time, file }] }]
    property var albums: []
    property var covers: ({})

    // "play" | "pause" | "stop"
    property string state: "stop"
    readonly property bool playing: state === "play"
    readonly property bool active: state !== "stop" && current.file !== ""
    property var current: ({ title: "", album: "", artist: "", file: "" })
    property real elapsed: 0
    property real duration: 0
    readonly property string currentCover: coverFor(current.file)
    // Índice en `albums` del álbum que suena (-1 si ninguno)
    readonly property int currentAlbum: albums.findIndex(a => a.dir === dirOf(current.file))

    // La vista lo activa mientras se ve, para refrescar el tiempo cada segundo
    property bool watching: false

    function dirOf(file) {
        const i = (file || "").lastIndexOf("/")
        return i < 0 ? "." : file.slice(0, i)
    }

    function coverFor(file) { return coverForDir(dirOf(file)) }

    function coverForDir(dir) {
        const c = covers[dir] ?? ""
        return c !== "" ? "file://" + c : ""
    }

    // "m:ss" o "h:mm:ss" -> segundos
    function seconds(t) {
        return (t || "").split(":").reduce((acc, p) => acc * 60 + (parseInt(p) || 0), 0)
    }

    // --- Acciones ---
    function playAlbum(album, index) {
        // Por archivo y en el orden de la lista: no depende de cómo estén etiquetados
        Quickshell.execDetached(["sh", "-c", 'n="$1"; shift; mpc -q clear && printf "%s\\n" "$@" | mpc -q add && mpc -q play "$n"',
                                 "sh", String(index + 1)].concat(album.tracks.map(t => t.file)))
    }
    function toggle() { Quickshell.execDetached(["mpc", "-q", "toggle"]) }
    function next() { Quickshell.execDetached(["mpc", "-q", "next"]) }
    function prev() { Quickshell.execDetached(["mpc", "-q", "prev"]) }
    function seek(fraction) { Quickshell.execDetached(["mpc", "-q", "seek", Math.round(fraction * 100) + "%"]) }

    // --- Biblioteca ---
    function reloadLibrary() { library.running = true }

    Process {
        id: library
        // albumartist, artist, album, track, title, time, file (separados por tabulador)
        command: ["mpc", "listall", "-f",
                  ["[%albumartist%]", "[%artist%]", "[%album%]", "[%track%]", "[%title%]", "[%time%]", "%file%"].join("\t")]
        stdout: StdioCollector {
            onStreamFinished: root.parseLibrary(text)
        }
    }

    function parseLibrary(text) {
        const groups = {}
        for (const line of text.split("\n")) {
            const f = line.split("\t")
            if (f.length < 7 || f[6] === "") continue
            const file = f[6]
            const dir = dirOf(file)
            const artist = f[0] || f[1] || "Desconocido"
            const album = f[2] || dir.split("/").pop() || "Sin álbum"
            const key = artist + "\u0000" + album
            if (!groups[key]) groups[key] = { key: key, album: album, artist: artist, dir: dir, tracks: [] }
            groups[key].tracks.push({
                title: f[4] || file.split("/").pop().replace(/\.[^.]+$/, ""),
                track: parseInt(f[3]) || 0,
                time: f[5],
                file: file
            })
        }
        const list = Object.values(groups)
        for (const a of list) a.tracks.sort((x, y) => x.track - y.track || x.file.localeCompare(y.file))
        list.sort((x, y) => x.artist.localeCompare(y.artist) || x.album.localeCompare(y.album))
        albums = list
        if (list.length > 0) {
            coverScan.command = ["sh", "-c", coverScript, "sh", musicDir].concat(list.map(a => a.dir))
            coverScan.running = true
        }
    }

    // Carátula por carpeta: archivo de la carpeta o imagen incrustada (en caché)
    readonly property string coverScript: '
        m="$1"; shift; c="$HOME/.cache/mpd-covers"; mkdir -p "$c"
        for d in "$@"; do
            f=""
            for n in cover folder front Cover Folder Front; do
                for e in jpg jpeg png; do
                    [ -z "$f" ] && [ -f "$m/$d/$n.$e" ] && f="$m/$d/$n.$e"
                done
            done
            if [ -z "$f" ]; then
                o="$c/$(printf %s "$d" | md5sum | cut -c1-32).jpg"
                if [ ! -s "$o" ]; then
                    a=$(find "$m/$d" -maxdepth 1 -type f \\( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.opus" \\) | sort | head -n 1)
                    [ -n "$a" ] && ffmpeg -nostdin -loglevel error -y -i "$a" -an -frames:v 1 "$o" 2>/dev/null
                fi
                [ -s "$o" ] && f="$o"
            fi
            printf "%s\\t%s\\n" "$d" "$f"
        done'

    Process {
        id: coverScan
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {}
                for (const line of text.split("\n")) {
                    const i = line.indexOf("\t")
                    if (i > 0) map[line.slice(0, i)] = line.slice(i + 1)
                }
                root.covers = map
                root.albums = root.albums.map(a => Object.assign({}, a, { cover: root.coverForDir(a.dir) }))
            }
        }
    }

    // --- Estado ---
    function refresh() { status.running = true }

    Process {
        id: status
        // Por sh: si mpc no está instalado falla sin avisos (y available queda en false)
        command: ["sh", "-c", 'mpc status "%state%\t%currenttime%\t%totaltime%" && mpc current -f "[%title%]\t[%album%]\t[[%albumartist%]|[%artist%]]\t%file%"']
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                const s = (lines[0] || "").split("\t")
                const c = (lines[1] || "").split("\t")
                root.state = s[0] === "playing" ? "play" : s[0] === "paused" ? "pause" : "stop"
                root.elapsed = root.seconds(s[1])
                root.duration = root.seconds(s[2])
                const file = c[3] || ""
                root.current = {
                    // Sin etiqueta de título: el nombre del archivo
                    title: c[0] || file.split("/").pop().replace(/\.[^.]+$/, ""),
                    album: c[1] || "",
                    artist: c[2] || "",
                    file: file
                }
            }
        }
        onExited: code => {
            const wasAvailable = root.available
            root.available = code === 0
            if (root.available && !wasAvailable) root.reloadLibrary()
            // Escuchar a MPD solo cuando responde; si no, volver a probar más tarde
            if (root.available) { if (!idle.running) idle.running = true }
            else retry.restart()
        }
    }

    // Avisos de MPD: cada línea es un subsistema que cambió
    Process {
        id: idle
        command: ["mpc", "idleloop", "player", "playlist", "database"]
        stdout: SplitParser {
            onRead: line => {
                if (line === "database") root.reloadLibrary()
                root.refresh()
            }
        }
        // MPD se paró o se reinició: volver a comprobar
        onExited: retry.restart()
    }

    Timer {
        id: retry
        interval: 5000
        onTriggered: root.refresh()
    }

    // El tiempo no se avisa: refrescar cada segundo mientras se ve y suena
    Timer {
        interval: 1000
        repeat: true
        running: root.watching && root.playing
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
