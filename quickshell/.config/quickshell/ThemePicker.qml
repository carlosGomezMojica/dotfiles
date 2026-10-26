import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Selector de tema + wallpaper con estilo cover flow (iPod classic).
// Se abre con `qs ipc call themes toggle` (SUPER + W). Aplica con el script `theme`.
PanelWindow {
    id: root

    property bool shown: false
    // Una carátula por wallpaper: { theme, path, name }; los temas sin imágenes tienen una sin path
    property var items: []
    // Paletas de todos los temas, por nombre (para las muestras de color)
    property var palettes: ({})

    readonly property var current: items[view.currentIndex] ?? null
    readonly property int cover: 280
    readonly property var swatches: ["accent", "highlight", "success", "warning", "error", "muted", "text"]

    function open() {
        shown = true
        scan.running = true
        view.forceActiveFocus()
    }

    function close() { shown = false }
    function toggle() { shown ? close() : open() }

    function apply(item) {
        if (!item) return
        const args = [Quickshell.env("HOME") + "/.local/bin/theme", item.theme]
        if (item.path !== "") args.push(item.path)
        Quickshell.execDetached(args)
        close()
    }

    // "catppuccin-mocha" -> "Catppuccin Mocha"
    function title(name) {
        return name.split("-").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ")
    }

    function isActive(item) {
        return item !== null && item.theme === Theme.name && item.path === Theme.wallpaper
    }

    // Lee paletas y wallpapers en cada apertura (así aparecen las imágenes nuevas)
    Process {
        id: scan
        command: ["sh", "-c", `
            for f in "$1"/palettes/*.json; do
                printf '\\n@palette %s\\n' "$(basename "$f" .json)"; cat "$f"
            done
            printf '\\n@wallpapers\\n'
            find -L "$1/wallpapers" -mindepth 2 -maxdepth 2 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\)
        `, "sh", Theme.dir]

        stdout: StdioCollector {
            onStreamFinished: root.load(text)
        }
    }

    function load(text) {
        const pals = {}
        let paths = []
        for (const section of ("\n" + text).split("\n@").slice(1)) {
            const nl = section.indexOf("\n")
            const head = section.slice(0, nl)
            const body = section.slice(nl + 1)
            if (head.startsWith("palette ")) {
                try { pals[head.slice(8)] = JSON.parse(body) } catch (e) {}
            } else if (head === "wallpapers") {
                paths = body.split("\n").filter(l => l !== "")
            }
        }

        const list = paths.map(p => {
            const parts = p.split("/")
            return { path: p, theme: parts[parts.length - 2], name: parts[parts.length - 1].replace(/\.[^.]+$/, "") }
        }).filter(it => it.theme in pals)
        for (const theme of Object.keys(pals))
            if (!list.some(it => it.theme === theme)) list.push({ path: "", theme: theme, name: "" })
        list.sort((a, b) => a.theme.localeCompare(b.theme) || a.name.localeCompare(b.name))

        palettes = pals
        items = list
        const active = list.findIndex(it => isActive(it))
        view.currentIndex = active >= 0 ? active : Math.max(0, list.findIndex(it => it.theme === Theme.name))
    }

    IpcHandler {
        target: "themes"
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
    WlrLayershell.namespace: "quickshell-themes"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: content.opacity = visible ? 1 : 0

    // Carátula: el wallpaper, o franjas con los colores del tema si no tiene (o mientras carga)
    component Art: Item {
        id: art
        property var entry
        property var colors

        Row {
            anchors.fill: parent
            visible: image.status !== Image.Ready

            Repeater {
                model: root.swatches
                Rectangle {
                    required property string modelData
                    width: art.width / root.swatches.length
                    height: art.height
                    color: art.colors?.[modelData] ?? Theme.surface
                }
            }
        }

        Image {
            id: image
            anchors.fill: parent
            source: art.entry.path !== "" ? "file://" + art.entry.path : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(512, 512)
            asynchronous: true
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // Fondo opaco como la pantalla del iPod; clic fuera de las carátulas cierra
        Rectangle {
            anchors.fill: parent
            color: Theme.bg

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
                onWheel: wheel => wheel.angleDelta.y > 0 ? view.decrementCurrentIndex() : view.incrementCurrentIndex()
            }
        }

        PathView {
            id: view

            // Centro de las carátulas, separación central y separación entre las apiladas
            readonly property real cx: width / 2
            readonly property real cy: root.cover / 2
            readonly property real gap: root.cover * 0.72
            readonly property real step: root.cover * 0.2
            // Número impar para que haya tantas a la izquierda como a la derecha
            readonly property int slots: Math.max(1, Math.min(11, count % 2 ? count : count - 1))

            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.42 - root.cover / 2
            width: parent.width
            height: root.cover * 2
            model: root.items
            pathItemCount: slots
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            highlightMoveDuration: 260
            snapMode: PathView.SnapOneItem
            focus: true

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier
                if (event.key === Qt.Key_Escape) root.close()
                else if (event.key === Qt.Key_Left || (ctrl && event.key === Qt.Key_H)) decrementCurrentIndex()   // Ctrl+H: izquierda (Dvorak)
                else if (event.key === Qt.Key_Right || (ctrl && event.key === Qt.Key_S)) incrementCurrentIndex()  // Ctrl+S: derecha (Dvorak)
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.apply(root.current)
                else return
                event.accepted = true
            }

            // Apiladas a los lados (giradas), la central de frente y separada
            path: Path {
                startX: view.cx - view.gap - (view.slots / 2 - 1) * view.step
                startY: view.cy
                PathAttribute { name: "angle"; value: -65 }
                PathAttribute { name: "depth"; value: 0 }
                PathAttribute { name: "size"; value: 0.85 }

                PathLine { x: view.cx - view.gap; y: view.cy }
                PathPercent { value: 0.5 - 1 / view.slots }
                PathAttribute { name: "angle"; value: -65 }
                PathAttribute { name: "depth"; value: 50 }
                PathAttribute { name: "size"; value: 0.85 }

                PathLine { x: view.cx; y: view.cy }
                PathPercent { value: 0.5 }
                PathAttribute { name: "angle"; value: 0 }
                PathAttribute { name: "depth"; value: 100 }
                PathAttribute { name: "size"; value: 1 }

                PathLine { x: view.cx + view.gap; y: view.cy }
                PathPercent { value: 0.5 + 1 / view.slots }
                PathAttribute { name: "angle"; value: 65 }
                PathAttribute { name: "depth"; value: 50 }
                PathAttribute { name: "size"; value: 0.85 }

                PathLine { x: view.cx + view.gap + (view.slots / 2 - 1) * view.step; y: view.cy }
                PathAttribute { name: "angle"; value: 65 }
                PathAttribute { name: "depth"; value: 0 }
                PathAttribute { name: "size"; value: 0.85 }
            }

            delegate: Item {
                id: card
                required property var modelData
                required property int index

                width: root.cover
                height: root.cover
                z: PathView.depth ?? 0
                scale: PathView.size ?? 1
                // Giro y escala desde el borde inferior ("suelo"): todas las carátulas apoyan en
                // la misma línea y el reflejo queda simétrico respecto a ella
                transformOrigin: Item.Bottom

                transform: Rotation {
                    origin.x: card.width / 2
                    origin.y: card.height
                    axis { x: 0; y: 1; z: 0 }
                    angle: card.PathView.angle ?? 0
                }

                Art {
                    anchors.fill: parent
                    entry: card.modelData
                    colors: root.palettes[card.modelData.theme]
                }

                // Reflejo: la carátula volteada, fundida hacia el fondo
                Art {
                    y: card.height
                    width: card.width
                    height: card.height
                    entry: card.modelData
                    colors: root.palettes[card.modelData.theme]
                    transform: Scale { origin.y: root.cover / 2; yScale: -1 }
                }

                Rectangle {
                    y: card.height
                    width: card.width
                    height: card.height
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.alpha(Theme.bg, 0.55) }
                        GradientStop { position: 0.55; color: Theme.bg }
                    }
                }

                TapHandler {
                    onTapped: card.PathView.isCurrentItem ? root.apply(card.modelData) : view.currentIndex = card.index
                }
            }
        }

        // Tema y wallpaper de la carátula central (como artista y álbum)
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: view.y + root.cover + 36
            spacing: 6
            visible: root.current !== null

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.current ? root.title(root.current.theme) : ""
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 20
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.current ? (root.current.name || "sin wallpaper") : ""
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 13
            }

            Item { width: 1; height: 6 }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: root.swatches
                        Rectangle {
                            required property string modelData
                            width: 10
                            height: 10
                            radius: 5
                            color: root.current ? (root.palettes[root.current.theme]?.[modelData] ?? Theme.surface) : Theme.surface
                        }
                    }
                }

                StatusPill {
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property bool active: root.isActive(root.current)
                    label: active ? "ACTIVO" : "APLICAR [ENTER]"
                    dotColor: active ? Theme.success : Theme.highlight
                    borderColor: active ? Theme.panelBorder : Theme.highlight
                    textColor: active ? Theme.text : Theme.highlight
                }
            }
        }

        // Pie con ayuda de teclado
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            width: help.implicitWidth + 24
            height: 24
            radius: height / 2
            color: Theme.bg
            border.width: 1
            border.color: Theme.panelBorder

            Text {
                id: help
                anchors.centerIn: parent
                text: root.items.length + " CARÁTULAS  ·  ←→ MOVER  ·  ENTER APLICAR  ·  ESC CERRAR"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 9
                font.letterSpacing: 1.5
            }
        }
    }
}
