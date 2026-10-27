import QtQuick

// Uso de IA en la barra expandida: robot + porcentaje de la sesión (abre AiPanel)
Row {
    id: root
    spacing: 6

    signal clicked()

    // Handlers (no ocupan sitio en el Row)
    TapHandler { onTapped: root.clicked() }
    HoverHandler { cursorShape: Qt.PointingHandCursor }

    CenteredText {
        text: String.fromCodePoint(0xF06A9)   // nf-md-robot
        color: Theme.warning
        font.family: Theme.font
        font.pixelSize: 16
    }

    // Mismo estilo y centrado que el porcentaje de la batería
    CenteredText {
        visible: Ai.hasLimits
        text: Math.round(Ai.sessionPercent * 100) + "%"
        metricsText: "0123456789"
        color: Theme.text
        font.pixelSize: 12
        font.bold: true
    }
}
