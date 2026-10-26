pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

// Estado de bluetooth compartido por la cápsula y el panel (bluez vía Quickshell.Bluetooth)
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false

    // Conectados primero, luego emparejados y después por nombre
    readonly property var devices: (adapter?.devices.values ?? [])
        .slice()
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    readonly property var paired: devices.filter(d => d.paired)
    // Descubiertos al buscar: sin emparejar y con nombre propio (no solo la MAC)
    readonly property var discovered: devices.filter(d => !d.paired && d.name !== "" && d.name.replace(/-/g, ":") !== d.address)
    readonly property var connected: devices.filter(d => d.connected)

    // Azul: algo conectado; rojo: encendido sin conexión; gris: apagado
    readonly property color stateColor: !enabled ? Theme.muted
        : connected.length > 0 ? Theme.info
        : Theme.error
    readonly property string stateLabel: !enabled ? "APAGADO"
        : connected.length > 0 ? "CONECTADO"
        : "ENCENDIDO"

    readonly property string icon: glyph(!enabled ? 0xF00B2          // nf-md-bluetooth_off
        : connected.length > 0 ? 0xF00B1                               // nf-md-bluetooth_connect
        : 0xF00AF)                                                     // nf-md-bluetooth

    // Texto junto al icono en la cápsula
    readonly property string summary: connected.length === 1 ? connected[0].name
        : connected.length > 1 ? connected.length + " disp."
        : ""

    function glyph(code) { return String.fromCodePoint(code) }

    // Icono freedesktop que reporta bluez -> glifo Nerd Font
    function deviceIcon(icon) {
        const i = icon ?? ""
        return glyph(i.startsWith("audio-head") ? 0xF02CB      // nf-md-headphones
            : i.startsWith("audio") ? 0xF04C3                    // nf-md-speaker
            : i === "input-mouse" ? 0xF037D                      // nf-md-mouse
            : i === "input-keyboard" ? 0xF030C                   // nf-md-keyboard
            : i === "input-gaming" ? 0xF0296                     // nf-md-gamepad_variant
            : i.startsWith("phone") ? 0xF011C                    // nf-md-cellphone
            : i === "computer" ? 0xF0379                         // nf-md-monitor
            : 0xF00AF)                                           // nf-md-bluetooth
    }
}
