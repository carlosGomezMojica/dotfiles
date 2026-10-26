import QtQuick

// Tarjeta del panel de IA (estilo de BatteryCard, en naranja): sesión de 5 h en el
// anillo, semana, tokens y próximo reinicio semanal
Rectangle {
    id: root

    readonly property color tone: Theme.warning   // naranja
    readonly property int padding: 20

    implicitWidth: 300
    implicitHeight: column.implicitHeight + padding * 2
    radius: 16
    color: Theme.bg
    border.width: 1
    border.color: Theme.panelBorder

    component Label: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 9
        font.letterSpacing: 1
    }

    component Value: Text {
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 18
    }

    component Heading: Text {
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 11
        font.letterSpacing: 1.5
    }

    Column {
        id: column
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 18

        // Cabecera
        Item {
            width: parent.width
            height: planPill.height

            Heading {
                anchors.verticalCenter: parent.verticalCenter
                text: "01  IA"
            }

            StatusPill {
                id: planPill
                anchors.right: parent.right
                label: !Ai.ready ? "CARGANDO…"
                     : !Ai.live ? "SIN CONEXIÓN"
                     : ("CLAUDE " + Ai.plan).trim().toUpperCase()
                dotColor: Ai.live ? root.tone : Theme.muted
                borderColor: Ai.live ? root.tone : Theme.panelBorder
                textColor: Ai.live ? root.tone : Theme.text
            }
        }

        // Anillo con el uso de la sesión (ventana de 5 h)
        Item {
            width: parent.width
            height: 150

            DotRing {
                anchors.centerIn: parent
                width: 150
                height: 150
                level: Ai.sessionPercent
                onColor: root.tone
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: percent
                        text: Ai.hasLimits ? Math.round(Ai.sessionPercent * 100) : "—"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 40
                        font.weight: Font.Light
                    }

                    Text {
                        anchors.baseline: percent.baseline
                        visible: Ai.hasLimits
                        text: "%"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 16
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Ai.until(Ai.sessionReset)
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 11
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "SESIÓN · REINICIA"
                }
            }
        }

        // Estadísticas
        Row {
            id: stats
            width: parent.width

            readonly property real cell: (width - 2) / 3

            Column {
                width: stats.cell
                spacing: 4
                Label { text: "SEMANA" }
                Value { text: Ai.hasLimits ? Math.round(Ai.weeklyPercent * 100) + "%" : "—" }
            }

            Rectangle { width: 1; height: 44; color: Theme.panelBorder }

            Column {
                width: stats.cell
                spacing: 4
                leftPadding: 12
                Label { text: "SESIÓN" }
                Value { text: Ai.formatTokens(Ai.sessionTokens) }
                Label { text: "TOKENS"; font.pixelSize: 8 }
            }

            Rectangle { width: 1; height: 44; color: Theme.panelBorder }

            Column {
                width: stats.cell
                spacing: 4
                leftPadding: 12
                Label { text: "HOY" }
                Value { text: Ai.formatTokens(Ai.todayTokens) }
                Label { text: "TOKENS"; font.pixelSize: 8 }
            }
        }

        // Semana: barra, tokens y próximo reinicio
        Column {
            width: parent.width
            spacing: 10

            Item {
                width: parent.width
                height: weekPill.height

                Heading {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "02  SEMANA"
                }

                StatusPill {
                    id: weekPill
                    anchors.right: parent.right
                    label: Ai.hasLimits ? Math.round(Ai.weeklyPercent * 100) + "% USADO" : "—"
                    dotColor: root.tone
                }
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Theme.surface

                Rectangle {
                    width: parent.width * Ai.weeklyPercent
                    height: parent.height
                    radius: 2
                    color: root.tone

                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }
            }

            Row {
                width: parent.width

                Column {
                    width: parent.width / 2
                    spacing: 4
                    Label { text: "TOKENS" }
                    Value { text: Ai.formatTokens(Ai.weeklyTokens); font.pixelSize: 15 }
                }

                Column {
                    width: parent.width / 2
                    spacing: 4
                    Label { text: "PRÓXIMO REINICIO" }
                    Value { text: Ai.until(Ai.weeklyReset); font.pixelSize: 15 }
                    Label {
                        text: Ai.formatReset(Ai.weeklyReset).toUpperCase()
                        font.pixelSize: 8
                    }
                }
            }
        }

        // Aviso si los límites no son actuales (sin conexión, sesión caducada…)
        Label {
            width: parent.width
            visible: Ai.error !== ""
            text: Ai.error
            color: Theme.warning
            wrapMode: Text.Wrap
            font.letterSpacing: 0
        }
    }
}
