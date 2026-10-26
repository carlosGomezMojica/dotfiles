pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Paleta activa, compartida con Hyprland (~/.config/theme).
// Los componentes usan Theme.<token>; nunca hex directos.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/theme"
    property string name: "catppuccin-mocha"

    readonly property color bg: colors.bg
    readonly property color border: colors.border
    readonly property color accent: colors.accent
    readonly property color muted: colors.muted
    readonly property color surface: colors.surface
    readonly property color text: colors.text
    readonly property color success: colors.success
    readonly property color error: colors.error
    readonly property color warning: colors.warning
    readonly property color highlight: colors.highlight
    readonly property color panelBorder: colors.panel_border

    // Fuente de los paneles (Nerd Font: incluye iconos)
    readonly property string font: "JetBrainsMono Nerd Font"

    // Nombre del tema activo (lo escribe el script `theme`)
    FileView {
        path: root.dir + "/current"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const n = text().trim()
            if (n !== "") root.name = n
        }
    }

    FileView {
        path: root.dir + "/palettes/" + root.name + ".json"
        watchChanges: true
        onFileChanged: reload()

        // Valores por defecto: Catppuccin Mocha (si falta el archivo o un token)
        JsonAdapter {
            id: colors
            property string bg: "#000000"
            property string border: "#1f1f1f"
            property string accent: "#cba6f7"
            property string muted: "#9399b2"
            property string surface: "#313244"
            property string text: "#cdd6f4"
            property string success: "#a6e3a1"
            property string error: "#f38ba8"
            property string warning: "#fab387"
            property string highlight: "#fab387"
            property string panel_border: "#313244"
        }
    }
}
