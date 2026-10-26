import Quickshell.Networking
import QtQuick

// Tarjeta del panel de red: conexión actual y redes wifi (conectar, desconectar, contraseña)
Rectangle {
    id: root

    // Red cuya contraseña se está escribiendo (null = ninguna)
    property var pskTarget: null
    readonly property bool editing: pskTarget !== null

    readonly property int padding: 20
    readonly property int rowHeight: 44
    readonly property int maxRows: 6

    function activate(network) {
        if (network.connected) network.disconnect()
        else if (network.known || Net.isOpen(network.security)) network.connect()
        else if (Net.needsPsk(network.security)) pskTarget = network
        else network.connect()   // EAP u otras: que NetworkManager decida
    }

    function cancelPsk() { pskTarget = null }

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
        elide: Text.ElideRight
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
            height: statePill.height

            Heading {
                anchors.verticalCenter: parent.verticalCenter
                text: "01  RED"
            }

            StatusPill {
                id: statePill
                anchors.right: parent.right
                label: Net.stateLabel
                dotColor: Net.stateColor
            }
        }

        // Conexión actual
        Column {
            width: parent.width
            spacing: 14

            Row {
                width: parent.width
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Net.icon
                    color: Net.stateColor
                    font.family: Theme.font
                    font.pixelSize: 26
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40
                    spacing: 2

                    Value {
                        width: parent.width
                        text: Net.wired ? "Cable" : Net.current?.name ?? "Sin conexión"
                    }

                    // Tipo de conexión y, a su derecha, la IP de la máquina
                    Row {
                        spacing: 10

                        Label {
                            text: Net.wired ? "ETHERNET" : Net.current ? "WIFI" : !Networking.wifiEnabled ? "WIFI APAGADO" : "ELIGE UNA RED"
                        }

                        Label {
                            visible: Net.online && Net.ip !== ""
                            text: Net.ip
                            color: Theme.text
                        }
                    }
                }
            }

            Row {
                id: stats
                width: parent.width
                visible: Net.online

                readonly property real cell: (width - 2) / 3

                Column {
                    width: stats.cell
                    spacing: 4
                    Label { text: "SEÑAL" }
                    Value { font.pixelSize: 15; text: Math.round(Net.signal * 100) + "%" }
                }

                Rectangle { width: 1; height: 38; color: Theme.panelBorder }

                Column {
                    width: stats.cell
                    spacing: 4
                    leftPadding: 12
                    Label { text: "SEGURIDAD" }
                    Value { font.pixelSize: 15; text: Net.wired ? "—" : Net.securityLabel(Net.current?.security) }
                }

                Rectangle { width: 1; height: 38; color: Theme.panelBorder }

                Column {
                    width: stats.cell
                    spacing: 4
                    leftPadding: 12
                    Label { text: "INTERFAZ" }
                    Value {
                        width: stats.cell - 12
                        font.pixelSize: 15
                        text: (Net.wired ?? Net.wifi)?.name ?? "—"
                    }
                }
            }
        }

        // Redes wifi
        Column {
            width: parent.width
            spacing: 10
            visible: Net.wifi !== null

            Item {
                width: parent.width
                height: wifiToggle.height

                Heading {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "02  REDES"
                }

                StatusPill {
                    id: wifiToggle
                    anchors.right: parent.right
                    label: Networking.wifiEnabled ? "WIFI ON" : "WIFI OFF"
                    dotColor: Networking.wifiEnabled ? Theme.success : Theme.muted

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

            Label {
                visible: Networking.wifiEnabled && list.count === 0
                text: "BUSCANDO REDES…"
            }

            ListView {
                id: list
                width: parent.width
                height: Math.min(contentHeight, root.maxRows * (root.rowHeight + spacing))
                visible: Networking.wifiEnabled
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Net.networks

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    readonly property bool editing: root.pskTarget === modelData
                    property bool failed: false
                    // Olvidar pide un segundo clic para confirmar
                    property bool confirmForget: false

                    onHoveredChanged: if (!hovered) confirmForget = false
                    readonly property bool hovered: hover.hovered

                    width: list.width
                    height: editing ? root.rowHeight + 46 : root.rowHeight
                    radius: 12
                    color: hover.hovered || editing ? Qt.tint(Theme.bg, Qt.alpha(Theme.highlight, 0.08)) : Theme.bg
                    border.width: 1
                    border.color: hover.hovered || editing ? Theme.highlight : Theme.panelBorder
                    clip: true

                    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Connections {
                        target: row.modelData
                        function onConnectionFailed(reason) {
                            row.failed = true
                            // Contraseña guardada incorrecta o inexistente: pedirla
                            if (reason === ConnectionFailReason.NoSecrets && Net.needsPsk(row.modelData.security))
                                root.pskTarget = row.modelData
                        }
                        function onStateChangingChanged() { if (row.modelData.stateChanging) row.failed = false }
                    }

                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

                    TapHandler {
                        onTapped: if (!row.editing && !forgetArea.containsMouse) root.activate(row.modelData)
                    }

                    Item {
                        width: parent.width
                        height: root.rowHeight

                        Text {
                            id: signalIcon
                            anchors.verticalCenter: parent.verticalCenter
                            x: 12
                            text: Net.signalIcon(row.modelData.signalStrength)
                            color: row.modelData.connected ? Theme.success : Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 16
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: signalIcon.right
                            anchors.leftMargin: 10
                            anchors.right: lock.left
                            anchors.rightMargin: 6
                            text: row.modelData.name
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        Text {
                            id: lock
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: actions.left
                            anchors.rightMargin: 8
                            visible: !Net.isOpen(row.modelData.security)
                            text: Net.glyph(0xF033E)   // nf-md-lock
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                        }

                        Row {
                            id: actions
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            spacing: 6

                            // Olvidar la red guardada (borra la conexión de NetworkManager)
                            StatusPill {
                                visible: row.modelData.known && (hover.hovered || row.confirmForget)
                                label: row.confirmForget ? "¿OLVIDAR?" : "OLVIDAR"
                                dotColor: Theme.error
                                borderColor: row.confirmForget ? Theme.error : Theme.panelBorder
                                textColor: row.confirmForget ? Theme.error : Theme.text

                                MouseArea {
                                    id: forgetArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (row.confirmForget) {
                                            row.confirmForget = false
                                            row.modelData.forget()
                                        } else {
                                            row.confirmForget = true
                                        }
                                    }
                                }
                            }

                            StatusPill {
                                id: pill
                                visible: label !== ""
                                label: row.modelData.stateChanging ? "CONECTANDO…"
                                     : row.failed ? "ERROR"
                                     : row.modelData.connected ? (hover.hovered ? "DESCONECTAR" : "CONECTADA")
                                     : row.modelData.known ? (hover.hovered ? "" : "GUARDADA")
                                     : ""
                                dotColor: row.modelData.stateChanging ? Theme.highlight
                                        : row.failed ? Theme.error
                                        : row.modelData.connected ? (hover.hovered ? Theme.error : Theme.success)
                                        : Theme.muted
                            }
                        }
                    }

                    // Contraseña para redes nuevas
                    Rectangle {
                        x: 12
                        y: root.rowHeight
                        width: parent.width - 24
                        height: 34
                        radius: 8
                        visible: row.editing
                        color: "transparent"
                        border.width: 1
                        border.color: psk.activeFocus ? Theme.accent : Theme.panelBorder

                        onVisibleChanged: {
                            psk.text = ""
                            if (visible) Qt.callLater(() => psk.forceActiveFocus())
                        }

                        Label {
                            id: pskLabel
                            anchors.verticalCenter: parent.verticalCenter
                            x: 10
                            text: "CONTRASEÑA"
                        }

                        TextInput {
                            id: psk
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: pskLabel.right
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            echoMode: TextInput.Password
                            color: Theme.text
                            selectionColor: Qt.alpha(Theme.accent, 0.35)
                            font.family: Theme.font
                            font.pixelSize: 12
                            clip: true

                            cursorDelegate: Rectangle { width: 2; color: Theme.accent }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) root.cancelPsk()
                                else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && text !== "") {
                                    row.modelData.connectWithPsk(text)
                                    root.cancelPsk()
                                } else return
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            Label {
                visible: root.editing
                text: "ENTER CONECTAR  ·  ESC CANCELAR"
            }
        }
    }
}
