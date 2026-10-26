import QtQuick

// Uso de IA en la barra expandida: robot + porcentaje de la sesión (abre AiPanel)
Row {
    id: root
    spacing: 6

    signal clicked()

    // Handlers (no ocupan sitio en el Row)
    TapHandler { onTapped: root.clicked() }
    HoverHandler { cursorShape: Qt.PointingHandCursor }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: String.fromCodePoint(0xF06A9)   // nf-md-robot
        color: Theme.warning
        font.family: Theme.font
        font.pixelSize: 15
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: Ai.hasLimits
        text: Math.round(Ai.sessionPercent * 100) + "%"
        color: Theme.text
        font.pixelSize: 12
        font.bold: true
    }
}
