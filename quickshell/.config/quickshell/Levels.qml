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
    readonly property real peak: muted ? 0 : peakMonitor.peak

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

    function toggleMute() {
        if (!sink?.audio) return
        fromUi.restart()
        sink.audio.muted = !sink.audio.muted
    }

    // --- Brillo ---
    readonly property string backlight: "/sys/class/backlight/intel_backlight"
    readonly property real brightness: {
        const max = parseInt(maxFile.text())
        return max > 0 ? parseInt(brightnessFile.text()) / max : 0   // 0..1, lineal
    }

    // sysfs no avisa de cambios: se recarga a mano (IPC de las teclas o tras ajustarlo aquí)
    FileView { id: maxFile; path: root.backlight + "/max_brightness" }
    FileView { id: brightnessFile; path: root.backlight + "/brightness" }

    function reloadBrightness() { brightnessFile.reload() }

    function setBrightness(p) {
        fromUi.restart()
        setter.command = ["brightnessctl", "-n2", "set", Math.round(Math.max(0, Math.min(1, p)) * 100) + "%"]
        setter.running = true
    }

    Process {
        id: setter
        onExited: root.reloadBrightness()
    }

    // --- Aviso en pantalla ---
    // "volume" | "brightness" | "": la cápsula se expande un momento con el nivel
    property string osd: ""

    function show(kind) {
        osd = kind
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
