pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick

// Estado de red compartido por la cápsula y el panel (NetworkManager vía Quickshell.Networking)
Singleton {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null

    // Redes con nombre: conectada primero, luego las guardadas y después por señal
    readonly property var networks: (wifi?.networks.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))
    readonly property var current: networks.find(n => n.connected) ?? null

    readonly property bool online: current !== null || wired !== null
    readonly property bool limited: online && (Networking.connectivity === NetworkConnectivity.Limited
                                            || Networking.connectivity === NetworkConnectivity.Portal)
    readonly property real signal: wired ? 1 : current?.signalStrength ?? 0   // 0..1

    readonly property string stateLabel: !online ? "SIN RED"
        : Networking.connectivity === NetworkConnectivity.Portal ? "PORTAL"
        : Networking.connectivity === NetworkConnectivity.Limited ? "LIMITADO"
        : "CONECTADO"
    readonly property color stateColor: !online ? Theme.error : limited ? Theme.warning : Theme.success

    // Glifo Nerd Font de la conexión actual
    readonly property string icon: wired ? glyph(0xF0200)                 // nf-md-ethernet
        : !Networking.wifiEnabled || !current ? glyph(0xF05AA)             // nf-md-wifi_off
        : signalIcon(signal)

    // IPv4 de la interfaz conectada; Quickshell.Networking no la expone
    readonly property string iface: (wired ?? (current ? wifi : null))?.name ?? ""
    property string ip: ""

    function refreshIp() {
        if (iface === "") ip = ""
        else ipProc.running = true
    }

    onIfaceChanged: refreshIp()
    onCurrentChanged: refreshIp()   // misma interfaz, otra red: otra IP

    Process {
        id: ipProc
        command: ["ip", "-4", "-o", "addr", "show", "dev", root.iface]
        stdout: StdioCollector {
            onStreamFinished: root.ip = (text.match(/inet ([\d.]+)/) ?? [])[1] ?? ""
        }
    }

    function glyph(code) { return String.fromCodePoint(code) }

    // nf-md-wifi_strength_1..4
    function signalIcon(s) {
        return glyph(s > 0.75 ? 0xF0928 : s > 0.5 ? 0xF0925 : s > 0.25 ? 0xF0922 : 0xF091F)
    }

    function securityLabel(sec) {
        switch (sec) {
        case WifiSecurityType.Open: return "ABIERTA"
        case WifiSecurityType.Owe: return "OWE"
        case WifiSecurityType.WpaPsk: return "WPA"
        case WifiSecurityType.Wpa2Psk: return "WPA2"
        case WifiSecurityType.Sae: return "WPA3"
        case WifiSecurityType.WpaEap: return "WPA-EAP"
        case WifiSecurityType.Wpa2Eap: return "WPA2-EAP"
        case WifiSecurityType.Wpa3SuiteB192: return "WPA3-EAP"
        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep: return "WEP"
        case WifiSecurityType.Leap: return "LEAP"
        default: return "—"
        }
    }

    function isOpen(sec) { return sec === WifiSecurityType.Open || sec === WifiSecurityType.Owe }

    // Las que se conectan con una contraseña (las empresariales EAP no)
    function needsPsk(sec) {
        return sec === WifiSecurityType.WpaPsk || sec === WifiSecurityType.Wpa2Psk
            || sec === WifiSecurityType.Sae || sec === WifiSecurityType.StaticWep
    }
}
