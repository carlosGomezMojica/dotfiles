import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Historial del portapapeles (cliphist), con el diseño del lanzador: buscador arriba,
// lista a la izquierda y vista previa a la derecha.
// Se abre con `qs ipc call clipboard toggle` (SUPER + SHIFT + V).
PanelWindow {
    id: root

    property bool shown: false
    property string query: ""
    property int selected: 0
    // Última posición del ratón; null tras abrir (ver onPositionChanged de las filas)
    property var lastMouse: null

    // [{ line, id, text, kind: "text"|"image"|"link", info }] (más reciente primero)
    property var entries: []
    property bool listed: false
    property bool available: true
    readonly property var results: search(query)
    readonly property var current: results[selected] ?? null

    // Vista previa del elemento seleccionado
    property string previewText: ""
    property string previewImage: ""

    readonly property int maxVisible: 7
    readonly property int rowHeight: 56
    readonly property int rowSpacing: 6
    readonly property string cacheDir: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-clipboard"

    function open() {
        query = ""
        input.text = ""
        selected = 0
        lastMouse = null
        listed = false
        list.running = true
        shown = true
        input.forceActiveFocus()
    }

    function close() { shown = false }
    function toggle() { shown ? close() : open() }

    // Copia la entrada (pasa a ser lo primero del portapapeles) y cierra
    function copy(entry) {
        if (!entry) return
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", entry.line])
        close()
    }

    function remove(entry) {
        if (!entry) return
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", entry.line])
        entries = entries.filter(e => e.id !== entry.id)
    }

    // Minúsculas y sin acentos
    function norm(s) {
        return (s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()
    }

    // Contiene el texto (por orden de recencia) y después coincidencias difusas
    function search(text) {
        const q = norm(text.trim())
        if (q === "") return entries
        const direct = [], fuzzy = []
        for (const e of entries) {
            const t = norm(e.text)
            if (t.includes(q)) { direct.push(e); continue }
            let i = 0
            for (const c of t) if (c === q[i]) i++
            if (i === q.length) fuzzy.push(e)
        }
        return direct.concat(fuzzy)
    }

    function parse(text) {
        const out = []
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t")
            if (tab <= 0) continue
            const id = line.slice(0, tab)
            const body = line.slice(tab + 1)
            // Imágenes: "[[ binary data 120 KiB png 1366x768 ]]"
            const img = body.match(/^\[\[ binary data (.+?) (\w+) (\d+)x(\d+) \]\]$/)
            if (img) {
                out.push({ line: line, id: id, text: "Imagen " + img[3] + "×" + img[4],
                           kind: "image", info: img[2].toUpperCase() + " · " + img[3] + "×" + img[4] + " · " + img[1] })
            } else {
                const link = /^https?:\/\/\S+$/.test(body.trim())
                out.push({ line: line, id: id, text: body, kind: link ? "link" : "text",
                           info: link ? "ENLACE" : body.length + " CARACTERES" })
            }
        }
        return out
    }

    function kindLabel(kind) { return kind === "image" ? "IMAGEN" : kind === "link" ? "ENLACE" : "TEXTO" }

    function kindIcon(kind) {
        return String.fromCodePoint(kind === "image" ? 0xF02E9      // nf-md-image
                                  : kind === "link" ? 0xF0337       // nf-md-link
                                  : 0xF09A8)                        // nf-md-text
    }

    function move(delta) {
        if (results.length === 0) return
        selected = (selected + delta + results.length) % results.length
        rows.positionViewAtIndex(selected, ListView.Contain)
    }

    onResultsChanged: selected = 0
    // Vista previa con un pequeño retardo: moverse rápido no lanza un proceso por fila
    onCurrentChanged: {
        previewText = ""
        previewImage = ""
        previewDelay.restart()
    }

    Timer {
        id: previewDelay
        interval: 120
        onTriggered: {
            const e = root.current
            if (!e) return
            if (e.kind === "image") {
                imageDecode.command = ["sh", "-c",
                    'mkdir -p "$2" && f="$2/$3.png" && { [ -s "$f" ] || printf "%s" "$1" | cliphist decode > "$f"; } && printf "%s" "$f"',
                    "sh", e.line, root.cacheDir, e.id]
                imageDecode.running = true
            } else {
                textDecode.command = ["sh", "-c", 'printf "%s" "$1" | cliphist decode | head -c 4000', "sh", e.line]
                textDecode.running = true
            }
        }
    }

    Process {
        id: list
        command: ["sh", "-c", "command -v cliphist >/dev/null || exit 127; cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = root.parse(text)
                root.listed = true
            }
        }
        onExited: code => root.available = code !== 127
    }

    Process {
        id: textDecode
        stdout: StdioCollector { onStreamFinished: root.previewText = text }
    }

    Process {
        id: imageDecode
        stdout: StdioCollector { onStreamFinished: root.previewImage = text !== "" ? "file://" + text : "" }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    // En el monitor enfocado
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: {
        content.opacity = visible ? 1 : 0
        content.anchors.verticalCenterOffset = visible ? -root.height * 0.06 : -root.height * 0.06 - 10
    }

    component Label: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 9
        font.letterSpacing: 1.5
    }

    // Velo: clic fuera del menú lo cierra
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, 0.6)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Column {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.height * 0.06 - 10
        width: Math.min(860, root.width - 80)
        spacing: 10
        opacity: 0

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // Buscador
        Rectangle {
            width: parent.width
            height: 64
            radius: 16
            color: Theme.bg
            border.width: 1
            border.color: input.activeFocus ? Theme.accent : Theme.panelBorder

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // Evita que los clics sobre la tarjeta cierren el menú
            MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: 18
                width: parent.width - 36
                spacing: 4

                Label { text: "01  PORTAPAPELES" }

                TextInput {
                    id: input
                    width: parent.width
                    color: Theme.text
                    selectionColor: Qt.alpha(Theme.accent, 0.35)
                    font.family: Theme.font
                    font.pixelSize: 20
                    clip: true
                    focus: true

                    onTextChanged: root.query = text

                    cursorDelegate: Rectangle {
                        width: 2
                        color: Theme.accent
                    }

                    Text {
                        visible: input.text === ""
                        text: "Escribe para buscar…"
                        color: Theme.surface
                        font: input.font
                    }

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier
                        const shift = event.modifiers & Qt.ShiftModifier
                        if (event.key === Qt.Key_Escape) root.close()
                        else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_T || event.key === Qt.Key_J))) root.move(1)   // Ctrl+T: abajo (Dvorak)
                        else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_N || event.key === Qt.Key_K))) root.move(-1)  // Ctrl+N: arriba (Dvorak)
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Tab) root.copy(root.current)
                        else if (shift && event.key === Qt.Key_Delete) root.remove(root.current)
                        else return
                        event.accepted = true
                    }
                }
            }
        }

        // Lista y vista previa
        Row {
            id: body
            width: parent.width
            spacing: 10

            readonly property real listHeight: root.maxVisible * (root.rowHeight + root.rowSpacing) - root.rowSpacing

            Item {
                width: 500
                height: body.listHeight

                ListView {
                    id: rows
                    anchors.fill: parent
                    spacing: root.rowSpacing
                    clip: true
                    model: root.results
                    currentIndex: root.selected
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool active: index === root.selected

                        width: rows.width
                        height: root.rowHeight
                        radius: 12
                        // Tinte opaco: que no se transparente lo que hay detrás
                        color: active ? Qt.tint(Theme.bg, Qt.alpha(Theme.highlight, 0.08)) : Theme.bg
                        border.width: 1
                        border.color: active ? Theme.highlight : Theme.panelBorder

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            // Solo con movimiento real del ratón (al mostrarse llega un evento sintético)
                            onPositionChanged: mouse => {
                                const p = mapToItem(null, mouse.x, mouse.y)
                                const moved = root.lastMouse !== null
                                    && (p.x !== root.lastMouse.x || p.y !== root.lastMouse.y)
                                root.lastMouse = p
                                if (moved) root.selected = row.index
                            }
                            onClicked: root.copy(row.modelData)
                        }

                        Text {
                            id: kindIcon
                            anchors.verticalCenter: parent.verticalCenter
                            x: 16
                            width: 24
                            text: root.kindIcon(row.modelData.kind)
                            color: row.active ? Theme.highlight : Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 20
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: kindIcon.right
                            anchors.leftMargin: 12
                            anchors.right: pills.left
                            anchors.rightMargin: 12
                            spacing: 3

                            Text {
                                width: parent.width
                                text: row.modelData.text.replace(/\s+/g, " ")
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: row.modelData.info
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 9
                                font.letterSpacing: 1
                                elide: Text.ElideRight
                            }
                        }

                        Row {
                            id: pills
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            spacing: 6

                            StatusPill {
                                label: root.kindLabel(row.modelData.kind)
                                dotColor: Theme.muted
                            }

                            StatusPill {
                                visible: row.active
                                label: "COPIAR [TAB]"
                                dotColor: Theme.highlight
                                borderColor: Theme.highlight
                                textColor: Theme.highlight
                            }
                        }
                    }
                }

                // Vacío o sin cliphist
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: root.listed && root.results.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: String.fromCodePoint(0xF014C)   // nf-md-clipboard_outline
                        color: Theme.surface
                        font.family: Theme.font
                        font.pixelSize: 48
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: !root.available ? "INSTALA cliphist"
                            : root.entries.length === 0 ? "HISTORIAL VACÍO"
                            : "SIN RESULTADOS"
                    }
                }
            }

            // Vista previa
            Rectangle {
                width: body.width - 500 - body.spacing
                height: body.listHeight
                radius: 16
                color: Theme.bg
                border.width: 1
                border.color: Theme.panelBorder

                // Evita que los clics sobre la tarjeta cierren el menú
                MouseArea { anchors.fill: parent }

                Item {
                    id: previewHeader
                    x: 18
                    y: 18
                    width: parent.width - 36
                    height: typePill.height

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "02  VISTA PREVIA"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 11
                        font.letterSpacing: 1.5
                    }

                    StatusPill {
                        id: typePill
                        anchors.right: parent.right
                        visible: root.current !== null
                        label: root.current ? root.kindLabel(root.current.kind) : ""
                        dotColor: Theme.highlight
                    }
                }

                // Texto completo
                Flickable {
                    id: textPreview
                    anchors.top: previewHeader.bottom
                    anchors.topMargin: 14
                    anchors.bottom: previewFooter.top
                    anchors.bottomMargin: 10
                    x: 18
                    width: parent.width - 36
                    clip: true
                    contentHeight: previewBody.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    visible: root.current !== null && root.current.kind !== "image"

                    Text {
                        id: previewBody
                        width: textPreview.width
                        text: root.previewText
                        color: root.current?.kind === "link" ? Theme.info : Theme.text
                        font.family: Theme.font
                        font.pixelSize: 12
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        textFormat: Text.PlainText
                    }
                }

                // Imagen entera (sin recortar), centrada en el recuadro
                Image {
                    anchors.top: previewHeader.bottom
                    anchors.topMargin: 14
                    anchors.bottom: previewFooter.top
                    anchors.bottomMargin: 10
                    x: 18
                    width: parent.width - 36
                    visible: root.current?.kind === "image"
                    source: root.previewImage
                    sourceSize: Qt.size(640, 640)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Label {
                    id: previewFooter
                    x: 18
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 16
                    width: parent.width - 36
                    text: root.current?.info ?? ""
                    elide: Text.ElideRight
                }
            }
        }

        // Pie con ayuda de teclado
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: help.implicitWidth + 24
            height: 24
            radius: height / 2
            color: Theme.bg
            border.width: 1
            border.color: Theme.panelBorder

            Label {
                id: help
                anchors.centerIn: parent
                text: root.results.length + " ELEMENTOS  ·  ↑↓ MOVER  ·  ENTER COPIAR  ·  SHIFT+SUPR BORRAR  ·  ESC CERRAR"
            }
        }
    }
}
