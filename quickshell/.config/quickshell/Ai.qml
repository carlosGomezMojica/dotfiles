pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Uso de Claude Code (sesión de 5 h y semana) para la cápsula central. Los datos salen de
// scripts/ai-usage.py: límites oficiales de la cuenta y tokens de los registros locales.
Singleton {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/ai-usage.py"

    property var data: null
    readonly property bool ready: data !== null
    readonly property string plan: data?.plan ?? ""
    readonly property real sessionPercent: Math.max(0, data?.session?.percent ?? 0)
    readonly property real weeklyPercent: Math.max(0, data?.weekly?.percent ?? 0)
    readonly property bool hasLimits: (data?.session?.percent ?? -1) >= 0
    readonly property var sessionReset: parse(data?.session?.resetsAt)
    readonly property var weeklyReset: parse(data?.weekly?.resetsAt)
    readonly property real sessionTokens: data?.session?.tokens ?? 0
    readonly property real weeklyTokens: data?.weekly?.tokens ?? 0
    readonly property real todayTokens: data?.today ?? 0
    readonly property bool live: data?.live ?? false
    readonly property string error: data?.error ?? ""

    // Reloj para las cuentas atrás
    property date now: new Date()

    function parse(iso) { return iso ? new Date(iso) : null }

    function refresh(force) {
        if (usage.running) return
        usage.command = ["python3", script].concat(force ? ["--force"] : [])
        usage.running = true
    }

    // 1234567 -> "1.2M", 345678 -> "346K"
    function formatTokens(n) {
        if (n >= 1e9) return (n / 1e9).toFixed(1) + "B"
        if (n >= 1e6) return (n / 1e6).toFixed(1) + "M"
        if (n >= 1e3) return Math.round(n / 1e3) + "K"
        return String(Math.round(n))
    }

    // Tiempo hasta `date`: "2H 13M", o "3D 4H" si falta más de un día
    function until(date) {
        if (!date) return "—"
        const mins = Math.max(0, Math.round((date - now) / 60000))
        const d = Math.floor(mins / 1440), h = Math.floor(mins % 1440 / 60), m = mins % 60
        return d > 0 ? d + "D " + h + "H" : h > 0 ? h + "H " + m + "M" : m + "M"
    }

    // "lunes 27 oct, 09:00"
    function formatReset(date) {
        // Redondeado al minuto: la API da la hora con segundos sueltos (08:59:59.9 -> 09:00)
        return date ? new Date(Math.round(date / 60000) * 60000).toLocaleString(Qt.locale(), "dddd d MMM, HH:mm") : "—"
    }

    Process {
        id: usage
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.data = JSON.parse(text) } catch (e) {}
            }
        }
    }

    // El script cachea los límites 15 min: refrescar cada 5 basta (y suma los tokens nuevos)
    Timer {
        interval: 5 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh(false)
    }

    Timer {
        interval: 30 * 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }
}
