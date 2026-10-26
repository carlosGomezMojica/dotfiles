import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Lanzador de aplicaciones. Se abre con `qs ipc call launcher toggle` (SUPER + A).
// Comandos: "/font" lista las fuentes instaladas y aplica la elegida (script `font`).
PanelWindow {
    id: root

    property bool shown: false
    property string query: ""
    property int selected: 0
    // Última posición del ratón; null tras abrir (ver onPositionChanged de las filas)
    property var lastMouse: null

    readonly property int maxVisible: 7
    readonly property int rowHeight: 56
    readonly property int rowSpacing: 6

    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var results: search(query)

    // --- /font: selector de fuente ---
    readonly property bool fontMode: norm(query).startsWith("/font")
    // { name, isFont, active, comment } por familia instalada (lo da el script `font`)
    property var fonts: []
    readonly property string fontScript: Quickshell.env("HOME") + "/.local/bin/font"

    onFontModeChanged: if (fontMode) fontList.running = true

    Process {
        id: fontList
        command: [root.fontScript]
        stdout: StdioCollector {
            onStreamFinished: {
                root.fonts = text.split("\n").filter(l => l.trim() !== "").map(l => ({
                    name: l.slice(2),
                    isFont: true,
                    active: l.startsWith("*"),
                    comment: "Aa Bb Cc 0123 — El veloz murciélago hindú"
                }))
            }
        }
    }

    function open() {
        query = ""
        input.text = ""
        selected = 0
        lastMouse = null
        shown = true
        input.forceActiveFocus()
    }

    function close() { shown = false }
    function toggle() { shown ? close() : open() }

    // Terminal para las apps con Terminal=true (nvim, htop, yazi...); igual que `terminal` en keybinds.lua
    readonly property string terminal: "kitty"

    function launch(entry) {
        if (!entry) return
        if (entry.isFont) {
            Quickshell.execDetached([fontScript, entry.name])
            close()
            return
        }
        // execute() no abre una terminal para las apps de terminal: hay que envolverlas
        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: [terminal, "-e"].concat(Array.from(entry.command)),
                workingDirectory: entry.workingDirectory || Quickshell.env("HOME")
            })
        } else {
            entry.execute()
        }
        close()
    }

    // Minúsculas y sin acentos
    function norm(s) {
        return (s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()
    }

    function score(entry, q) {
        const name = norm(entry.name)
        if (name === q) return 1000
        if (name.startsWith(q)) return 900 - name.length
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 800 - name.length
        if (name.includes(q)) return 700 - name.indexOf(q)
        const extra = norm([entry.genericName, entry.comment].concat(Array.from(entry.keywords || [])).join(" "))
        if (extra.includes(q)) return 500
        // Coincidencia difusa: las letras de la consulta aparecen en orden en el nombre
        let i = 0
        for (const c of name) if (c === q[i]) i++
        return i === q.length ? 300 - name.length : 0
    }

    function search(text) {
        let q = norm(text.trim())
        let items = apps
        // "/font texto": buscar entre las fuentes, la activa primero
        if (q.startsWith("/font")) {
            q = q.slice(5).trim()
            items = fonts.slice().sort((a, b) => b.active - a.active)
        }
        if (q === "") return items
        return items
            .map(e => ({ entry: e, score: score(e, q) }))
            .filter(r => r.score > 0)
            .sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name))
            .map(r => r.entry)
    }

    function category(entry) {
        if (entry.isFont) return entry.active ? "ACTIVA" : "FUENTE"
        const cats = Array.from(entry.categories || [])
        const map = [
            ["Development", "DESARROLLO"], ["Game", "JUEGOS"], ["Graphics", "GRÁFICOS"],
            ["AudioVideo", "MULTIMEDIA"], ["Audio", "MULTIMEDIA"], ["Video", "MULTIMEDIA"],
            ["Network", "INTERNET"], ["Office", "OFICINA"], ["System", "SISTEMA"],
            ["Settings", "SISTEMA"], ["Utility", "UTILIDADES"]
        ]
        const hit = map.find(([key]) => cats.includes(key))
        return hit ? hit[1] : "APP"
    }

    function move(delta) {
        if (results.length === 0) return
        selected = (selected + delta + results.length) % results.length
        list.positionViewAtIndex(selected, ListView.Contain)
    }

    onResultsChanged: selected = 0

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
        // Abre con un texto ya escrito, p. ej. `qs ipc call launcher openWith /font`
        function openWith(text: string): void {
            root.open()
            input.text = text
        }
    }

    // En el monitor enfocado
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: {
        content.opacity = visible ? 1 : 0
        content.anchors.verticalCenterOffset = visible ? -root.height * 0.12 : -root.height * 0.12 - 10
    }

    // Velo: clic fuera del lanzador lo cierra
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
        anchors.verticalCenterOffset: -root.height * 0.12 - 10
        width: 560
        spacing: 10
        opacity: 0

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // Campo de búsqueda
        Rectangle {
            width: parent.width
            height: 64
            radius: 16
            color: Theme.bg
            border.width: 1
            border.color: input.activeFocus ? Theme.accent : Theme.panelBorder

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // Evita que los clics sobre la tarjeta cierren el lanzador
            MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: 18
                width: parent.width - 36
                spacing: 4

                Text {
                    text: "01  BUSCAR"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                }

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
                        if (event.key === Qt.Key_Escape) root.close()
                        else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_T || event.key === Qt.Key_J))) root.move(1)   // Ctrl+T: abajo (Dvorak)
                        else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_N || event.key === Qt.Key_K))) root.move(-1)  // Ctrl+N: arriba (Dvorak)
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Tab)
                            root.launch(root.results[root.selected])
                        else return
                        event.accepted = true
                    }
                }
            }
        }

        // Resultados
        ListView {
            id: list
            width: parent.width
            height: Math.max(0, Math.min(count, root.maxVisible) * (root.rowHeight + root.rowSpacing) - root.rowSpacing)
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

                width: list.width
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
                    // Solo con movimiento real del ratón: al mostrarse la ventana Qt envía un
                    // evento sintético que haría saltar la selección a la fila bajo el cursor
                    onPositionChanged: mouse => {
                        const p = mapToItem(null, mouse.x, mouse.y)
                        const moved = root.lastMouse !== null
                            && (p.x !== root.lastMouse.x || p.y !== root.lastMouse.y)
                        root.lastMouse = p
                        if (moved) root.selected = row.index
                    }
                    onClicked: root.launch(row.modelData)
                }

                // Icono del tema, o glifo genérico si la app no tiene
                Item {
                    id: iconBox
                    anchors.verticalCenter: parent.verticalCenter
                    x: 14
                    width: 28
                    height: 28

                    Image {
                        id: icon
                        anchors.fill: parent
                        source: row.modelData.isFont ? "" : Quickshell.iconPath(row.modelData.icon, true)
                        sourceSize: Qt.size(56, 56)
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    // Fuentes (/font): "Aa" con esa misma fuente
                    Text {
                        anchors.centerIn: parent
                        visible: !icon.visible
                        text: row.modelData.isFont ? "Aa" : String.fromCodePoint(0xF08C6)   // nf-md-application
                        color: row.modelData.isFont ? Theme.accent : Theme.muted
                        font.family: row.modelData.isFont ? row.modelData.name : Theme.font
                        font.pixelSize: row.modelData.isFont ? 18 : 22
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: iconBox.right
                    anchors.leftMargin: 14
                    anchors.right: pills.left
                    anchors.rightMargin: 12
                    spacing: 3

                    Text {
                        width: parent.width
                        text: row.modelData.name
                        color: Theme.text
                        font.family: row.modelData.isFont ? row.modelData.name : Theme.font
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: row.modelData.comment || row.modelData.genericName || ""
                        color: Theme.muted
                        font.family: row.modelData.isFont ? row.modelData.name : Theme.font
                        font.pixelSize: 10
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
                        label: root.category(row.modelData)
                        dotColor: Theme.muted
                    }

                    StatusPill {
                        visible: row.active
                        label: row.modelData.isFont ? "APLICAR [TAB]" : "ABRIR [TAB]"
                        dotColor: Theme.highlight
                        borderColor: Theme.highlight
                        textColor: Theme.highlight
                    }
                }
            }
        }

        // Pie con ayuda de teclado (con fondo para leerse sobre cualquier ventana)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: help.implicitWidth + 24
            height: 24
            radius: height / 2
            color: Theme.bg
            border.width: 1
            border.color: Theme.panelBorder

            Text {
                id: help
                anchors.centerIn: parent
                text: root.results.length === 0
                    ? "SIN RESULTADOS"
                    : root.fontMode
                    ? root.results.length + " FUENTES  ·  ↑↓ MOVER  ·  ENTER APLICAR  ·  ESC CERRAR"
                    : root.results.length + " RESULTADOS  ·  ↑↓ MOVER  ·  ENTER ABRIR  ·  ESC CERRAR  ·  /font FUENTES"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 9
                font.letterSpacing: 1.5
            }
        }
    }
}
