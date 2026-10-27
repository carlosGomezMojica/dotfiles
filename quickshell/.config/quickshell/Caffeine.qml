pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Cafeína: mientras está activa, cada Bar mantiene un IdleInhibitor (protocolo Wayland
// idle-inhibit, que hypridle respeta) y la pantalla no se apaga ni el equipo se suspende
// por inactividad. Empieza apagada en cada sesión.
Singleton {
    id: root

    property bool active: false

    function toggle() { active = !active }

    IpcHandler {
        target: "caffeine"
        function toggle(): void { root.toggle() }
        function on(): void { root.active = true }
        function off(): void { root.active = false }
    }
}
