pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// Volumen (PipeWire), brillo (sysfs + brightnessctl) y el aviso en pantalla (OSD) de la cápsula de indicadores.
// Singleton: IndicatorBar se crea una por monitor y el IpcHandler no puede repetirse.
Singleton {
    id: root

    // --- Audio ---
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0     // 0..1
    readonly property bool muted: sink?.audio?.muted ?? false
    // Nivel del audio que suena ahora (0..1), para el medidor
    readonly property real peak: muted ? 0 : (peakMonitor.peak ?? 0)

    // Sin tracker las propiedades de audio del sink no se cargan ni se pueden escribir
    PwObjectTracker { objects: [root.sink] }

    PwNodePeakMonitor {
        id: peakMonitor
        node: root.sink
        enabled: root.sink !== null
    }

    function setVolume(v) {
        if (!sink?.audio) return
        fromUi.restart()
        sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    // Ajuste relativo (rueda o dos dedos sobre la cápsula)
    function nudgeVolume(d) { setVolume(volume + d) }

    function toggleMute() {
        if (!sink?.audio) return
        fromUi.restart()
        sink.audio.muted = !sink.audio.muted
    }

    // --- Brillo ---
    readonly property string backlight: "/sys/class/backlight/intel_backlight"
    readonly property real brightness: target >= 0 ? target : sysBrightness   // 0..1, lineal
    readonly property real sysBrightness: {
        const max = parseInt(maxFile.text())
        return max > 0 ? parseInt(brightnessFile.text()) / max : 0
    }
    // Valor pedido mientras brightnessctl lo aplica (-1 = ninguno): el porcentaje responde al instante
    property real target: -1
    property real sent: -1

    // sysfs no avisa de cambios: se recarga a mano (IPC de las teclas o tras ajustarlo aquí)
    FileView { id: maxFile; path: root.backlight + "/max_brightness" }
    FileView { id: brightnessFile; path: root.backlight + "/brightness" }

    function reloadBrightness() { brightnessFile.reload() }

    // Deslizar con dos dedos genera muchos eventos: no se lanza un brightnessctl por cada
    // uno; mientras hay uno en marcha solo se guarda el último valor y se aplica al terminar
    function setBrightness(p) {
        fromUi.restart()
        clearTarget.stop()
        target = Math.max(0.01, Math.min(1, p))
        if (!setter.running) applyBrightness()
    }

    function nudgeBrightness(d) { setBrightness(brightness + d) }

    function applyBrightness() {
        sent = target
        setter.command = ["brightnessctl", "-n2", "set", Math.round(target * 100) + "%"]
        setter.running = true
    }

    Process {
        id: setter
        onExited: {
            if (Math.abs(root.target - root.sent) > 0.001) {
                root.applyBrightness()
            } else {
                root.reloadBrightness()
                clearTarget.restart()
            }
        }
    }

    // Tras el último ajuste, volver a mostrar lo que dice sysfs (ya recargado)
    Timer {
        id: clearTarget
        interval: 300
        onTriggered: root.target = -1
    }

    // --- Aviso en pantalla ---
    // "volume" | "brightness" | "media" | "": la cápsula se expande un momento
    // con el nivel o con lo que empieza a sonar (Media.qml)
    property string osd: ""

    function show(kind, duration = 1500) {
        osd = kind
        osdTimer.interval = duration
        osdTimer.restart()
    }

    Timer {
        id: osdTimer
        interval: 1500
        onTriggered: root.osd = ""
    }

    // Cambios hechos desde los sliders: no hace falta el aviso (la tarjeta ya está a la vista)
    Timer { id: fromUi; interval: 300 }
    // La primera carga del sink tampoco es un cambio del usuario
    Timer { id: settle; interval: 1500; running: true }

    onVolumeChanged: if (!fromUi.running && !settle.running) show("volume")
    onMutedChanged: if (!fromUi.running && !settle.running) show("volume")

    // Las teclas de brillo llaman a `qs ipc call indicators brightness` tras brightnessctl
    IpcHandler {
        target: "indicators"
        function brightness(): void {
            root.reloadBrightness()
            root.show("brightness")
        }
        function volume(): void { root.show("volume") }
        // Muestra lo que suena ahora (Media.qml)
        function media(): void { if (Media.ready) root.show("media", 4000) }
    }

    // Glifos Nerd Font según el nivel
    function volumeIcon(v, m) {
        return String.fromCodePoint(m || v <= 0 ? 0xF075F        // nf-md-volume_off
            : v < 0.34 ? 0xF057F                                 // nf-md-volume_low
            : v < 0.67 ? 0xF0580                                 // nf-md-volume_medium
            : 0xF057E)                                           // nf-md-volume_high
    }

    function brightnessIcon(b) {
        return String.fromCodePoint(b < 0.34 ? 0xF00DE          // nf-md-brightness_5
            : b < 0.67 ? 0xF00DF                                 // nf-md-brightness_6
            : 0xF00E0)                                           // nf-md-brightness_7
    }
}
