import Quickshell
import QtQuick

// Cápsula de energía pegada a la esquina inferior izquierda, sin margen: solo redondeada
// arriba a la derecha, como si saliera del borde. Colapsada: solo el símbolo de apagado.
// Al pasar el ratón muestra bloquear, cerrar sesión, suspender, hibernar, reiniciar y apagar;
// todas salvo bloquear piden un segundo clic (en 3 s) para confirmar.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    // Anclada a todo el borde inferior (transparente; la máscara limita el ratón a la cápsula)
    // porque una capa en una esquina no puede reservar espacio. Reserva lo justo para que
    // las ventanas no queden debajo de la cápsula colapsada: su alto (19) menos gaps_out (14)
    // más el borde de ventana (2) y 1 px de aire.
    anchors { bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 8
    color: "transparent"

    implicitHeight: 29

    readonly property real expandedWidth: content.implicitWidth + 27

    // Solo el hotspot recibe el mouse; el resto deja pasar los clicks
    mask: Region { item: hotspot }

    readonly property bool expanded: hover.hovered
    // Acción bajo el ratón y acción pendiente de confirmar (-1: ninguna)
    readonly property int hoveredIndex: hover.hovered ? indexAt(hover.point.position.x) : -1
    property int armed: -1

    onExpandedChanged: if (!expanded) armed = -1

    readonly property var actions: [
        { glyph: 0xF033E, label: "BLOQUEAR", color: Theme.accent, confirm: false,   // nf-md-lock
          command: ["loginctl", "lock-session"] },
        { glyph: 0xF0343, label: "CERRAR SESIÓN", color: Theme.info, confirm: true,   // nf-md-logout
          command: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"] },
        { glyph: 0xF04B2, label: "SUSPENDER", color: Theme.aqua, confirm: true,   // nf-md-power_sleep
          command: ["systemctl", "suspend"] },
        { glyph: 0xF0717, label: "HIBERNAR", color: Theme.yellow, confirm: true,   // nf-md-snowflake
          command: ["sh", "-c", "systemctl hibernate || notify-send -u critical Energía 'No se puede hibernar: hace falta una swap en disco y el parámetro resume'"] },
        { glyph: 0xF0709, label: "REINICIAR", color: Theme.warning, confirm: true,   // nf-md-restart
          command: ["systemctl", "reboot"] },
        { glyph: 0xF0425, label: "APAGAR", color: Theme.error, confirm: true,   // nf-md-power
          command: ["systemctl", "poweroff"] }
    ]

    // Índice de la acción en la x dada (coordenadas del hotspot)
    function indexAt(x) {
        for (let i = 0; i < buttons.count; i++) {
            const item = buttons.itemAt(i)
            const left = item.mapToItem(hotspot, 0, 0).x - content.spacing / 2
            if (x >= left && x < left + item.width + content.spacing) return i
        }
        return -1
    }

    function activate(i) {
        const action = actions[i]
        if (action.confirm && armed !== i) { armed = i; disarm.restart(); return }
        armed = -1
        Quickshell.execDetached(action.command)
    }

    Timer { id: disarm; interval: 3000; onTriggered: bar.armed = -1 }

    // Zona de detección: estable, sin animaciones
    Item {
        id: hotspot
        // Colapsada: la cápsula pequeña. Expandida: toda la cápsula.
        width: bar.expanded ? bar.expandedWidth : pill.collapsedWidth
        height: bar.expanded ? parent.height : pill.collapsedHeight
        y: parent.height - height
        z: 1

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        // El hotspot tapa la cápsula: el clic se reparte según la posición de los botones
        TapHandler {
            onTapped: eventPoint => {
                const i = bar.indexAt(eventPoint.position.x)
                if (i >= 0) bar.activate(i)
            }
        }
    }

    Rectangle {
        id: pill
        readonly property bool expanded: bar.expanded
        readonly property real collapsedWidth: 34
        readonly property real collapsedHeight: 19

        // Un píxel fuera de la pantalla por la izquierda y por abajo: el borde solo se ve
        // arriba y a la derecha
        x: -1
        y: bar.height - height + 1
        width: (expanded ? bar.expandedWidth : collapsedWidth) + 1
        height: (expanded ? 29 : collapsedHeight) + 1
        radius: 0
        topRightRadius: height / 2
        color: Theme.bg
        border.width: 1
        border.color: bar.armed >= 0 ? Theme.error : Theme.border

        Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        // Zona visible de la cápsula colapsada (la pill sobresale 1 px por la izquierda y por abajo)
        Item {
            x: 1
            width: pill.collapsedWidth
            height: pill.collapsedHeight
            opacity: pill.expanded ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }

            CenteredText {
                id: powerIcon
                // Centrado también en horizontal por el dibujo del glifo, no por su avance
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: width / 2
                    - (powerMetrics.tightBoundingRect.x + powerMetrics.tightBoundingRect.width / 2)
                text: String.fromCodePoint(0xF0425)   // nf-md-power
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 19

                TextMetrics { id: powerMetrics; font: powerIcon.font; text: powerIcon.text }
            }
        }

        Row {
            id: content
            anchors.centerIn: parent
            height: parent.height
            spacing: 12
            opacity: pill.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Repeater {
                id: buttons
                model: bar.actions

                Item {
                    required property var modelData
                    required property int index
                    readonly property bool hot: bar.hoveredIndex === index || bar.armed === index

                    width: glyph.implicitWidth
                    height: parent.height

                    CenteredText {
                        id: glyph
                        text: String.fromCodePoint(modelData.glyph)
                        color: bar.armed === index ? Theme.error : parent.hot ? modelData.color : Theme.text
                        font.family: Theme.font
                        font.pixelSize: 14

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 12
                color: Theme.border
            }

            // Nombre de la acción bajo el ratón, o la pregunta de confirmación.
            // Ancho fijo (el del texto más largo) para que la cápsula no cambie de tamaño.
            Item {
                width: longest.width
                height: parent.height

                TextMetrics {
                    id: longest
                    font: hint.font
                    text: "¿CERRAR SESIÓN?"
                }

                CenteredText {
                    id: hint
                    readonly property int shown: bar.armed >= 0 ? bar.armed : bar.hoveredIndex
                    text: shown < 0 ? "ENERGÍA"
                        : bar.armed >= 0 ? "¿" + bar.actions[shown].label + "?"
                        : bar.actions[shown].label
                    color: bar.armed >= 0 ? Theme.error : shown < 0 ? Theme.muted : Theme.text
                    font.family: Theme.font
                    font.pixelSize: 9
                    font.letterSpacing: 0.85
                }
            }
        }
    }
}
