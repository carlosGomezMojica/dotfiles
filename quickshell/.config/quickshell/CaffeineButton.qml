import QtQuick

// Cafeína en la barra expandida: taza llena (amarilla) activa, vacía (gris) apagada
Item {
    id: root

    implicitWidth: cup.implicitWidth
    implicitHeight: cup.implicitHeight

    TapHandler { onTapped: Caffeine.toggle() }
    HoverHandler { cursorShape: Qt.PointingHandCursor }

    CenteredText {
        id: cup
        text: String.fromCodePoint(Caffeine.active ? 0xF0176 : 0xF06CA)   // nf-md-coffee / coffee_outline
        color: Caffeine.active ? Theme.yellow : Theme.muted
        font.family: Theme.font
        font.pixelSize: 16

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
