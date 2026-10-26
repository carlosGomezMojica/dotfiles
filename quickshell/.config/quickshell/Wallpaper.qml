import Quickshell
import Quickshell.Wayland
import QtQuick

// Fondo de escritorio de un monitor: dibuja Theme.wallpaper con fundido al cambiar
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.bg

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"

    // Dos capas: la nueva imagen carga en la oculta y aparece encima cuando está lista
    property Image front: a
    property Image back: b

    function show(source) {
        if (source === "") {
            front.opacity = 0
            return
        }
        const url = "file://" + source
        if (front.source.toString() === url && front.opacity === 1) return
        // La capa oculta está debajo: bajarla a 0 no se ve
        back.opacity = 0
        back.source = ""
        back.source = url
    }

    Component.onCompleted: show(Theme.wallpaper)

    Connections {
        target: Theme
        function onWallpaperChanged() { root.show(Theme.wallpaper) }
    }

    component Layer: Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.screen.width, root.screen.height)
        asynchronous: true
        cache: false
        opacity: 0

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }

        onStatusChanged: {
            if (status !== Image.Ready || img !== root.back) return
            root.back.z = 1
            root.front.z = 0
            root.back.opacity = 1   // la anterior queda debajo, opaca: sin destello del color bg
            const old = root.front
            root.front = root.back
            root.back = old
        }
    }

    Layer { id: a }
    Layer { id: b }
}
