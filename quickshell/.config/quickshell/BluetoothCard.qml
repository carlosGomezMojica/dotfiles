import Quickshell.Bluetooth
import QtQuick

// Tarjeta del panel de bluetooth: encendido, dispositivos emparejados y búsqueda de nuevos
Rectangle {
    id: root

    readonly property int padding: 20
    readonly property int rowHeight: 44
    readonly property int maxRows: 4

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

    // Píldora clicable (interruptor, buscar)
    component PillButton: StatusPill {
        id: button
        signal clicked()

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    // Fila de dispositivo, emparejado o descubierto
    component DeviceRow: Rectangle {
        id: row
        required property var modelData
        readonly property var device: modelData
        readonly property bool busy: device.state === BluetoothDeviceState.Connecting
                                  || device.state === BluetoothDeviceState.Disconnecting
                                  || device.pairing
        // Se intentó emparejar o conectar y no se logró
        property bool failed: false
        property bool attempted: false
        // Olvidar pide un segundo clic para confirmar
        property bool confirmForget: false

        function activate() {
            failed = false
            if (device.pairing) device.cancelPair()
            else if (device.connected) device.disconnect()
            else if (device.paired) { attempted = true; device.connect() }
            else {
                // Nuevo: emparejar, confiar en él y conectar al terminar (ver onPairedChanged)
                attempted = true
                device.trusted = true
                device.pair()
            }
        }

        width: ListView.view.width
        height: root.rowHeight
        radius: 12
        color: hover.hovered ? Qt.tint(Theme.bg, Qt.alpha(Theme.highlight, 0.08)) : Theme.bg
        border.width: 1
        border.color: hover.hovered ? Theme.highlight : Theme.panelBorder

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Connections {
            target: row.device
            function onPairedChanged() { if (row.device.paired && row.attempted) row.device.connect() }
            function onConnectedChanged() { if (row.device.connected) { row.attempted = false; row.failed = false } }
            function onStateChanged() {
                if (row.attempted && row.device.state === BluetoothDeviceState.Disconnected && !row.device.pairing) {
                    row.attempted = false
                    row.failed = !row.device.connected
                }
            }
            function onPairingChanged() {
                if (!row.device.pairing && row.attempted && !row.device.paired) {
                    row.attempted = false
                    row.failed = true
                }
            }
        }

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: if (!hovered) row.confirmForget = false
        }

        TapHandler {
            onTapped: if (!forgetArea.containsMouse) row.activate()
        }

        Text {
            id: deviceIcon
            anchors.verticalCenter: parent.verticalCenter
            x: 12
            text: Bt.deviceIcon(row.device.icon)
            color: row.device.connected ? Theme.info : Theme.muted
            font.family: Theme.font
            font.pixelSize: 16
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: deviceIcon.right
            anchors.leftMargin: 10
            anchors.right: battery.left
            anchors.rightMargin: 6
            text: row.device.name
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        // Batería del dispositivo (0..1), si la reporta
        Text {
            id: battery
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: actions.left
            anchors.rightMargin: 8
            visible: row.device.batteryAvailable
            text: Math.round(row.device.battery * 100) + "%"
            color: row.device.battery <= 0.2 ? Theme.error : Theme.success
            font.family: Theme.font
            font.pixelSize: 10
        }

        Row {
            id: actions
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 10
            spacing: 6

            // Olvidar el dispositivo emparejado
            StatusPill {
                visible: row.device.paired && (hover.hovered || row.confirmForget)
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
                            row.device.forget()
                        } else {
                            row.confirmForget = true
                        }
                    }
                }
            }

            StatusPill {
                visible: label !== ""
                label: row.device.pairing ? (hover.hovered ? "CANCELAR" : "EMPAREJANDO…")
                     : row.busy ? "CONECTANDO…"
                     : row.failed ? "ERROR"
                     : row.device.connected ? (hover.hovered ? "DESCONECTAR" : "CONECTADO")
                     : !row.device.paired && hover.hovered ? "EMPAREJAR"
                     : ""
                dotColor: row.busy ? Theme.highlight
                        : row.failed ? Theme.error
                        : row.device.connected ? (hover.hovered ? Theme.error : Theme.info)
                        : Theme.highlight
            }
        }
    }

    Column {
        id: column
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 18

        // Cabecera
        Column {
            width: parent.width
            spacing: 14

            Item {
                width: parent.width
                height: statePill.height

                Heading {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "01  BLUETOOTH"
                }

                StatusPill {
                    id: statePill
                    anchors.right: parent.right
                    label: Bt.stateLabel
                    dotColor: Bt.stateColor
                }
            }

            Row {
                width: parent.width
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Bt.icon
                    color: Bt.stateColor
                    font.family: Theme.font
                    font.pixelSize: 26
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40 - power.width
                    spacing: 2

                    Value {
                        width: parent.width
                        text: Bt.adapter?.name ?? "Sin adaptador"
                    }

                    Label {
                        text: !Bt.enabled ? "APAGADO"
                            : Bt.connected.length === 1 ? "1 CONECTADO"
                            : Bt.connected.length + " CONECTADOS"
                    }
                }

                PillButton {
                    id: power
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Bt.adapter !== null
                    label: Bt.enabled ? "BT ON" : "BT OFF"
                    dotColor: Bt.enabled ? Theme.info : Theme.muted
                    onClicked: Bt.adapter.enabled = !Bt.enabled
                }
            }
        }

        // Emparejados
        Column {
            width: parent.width
            spacing: 10
            visible: Bt.enabled

            Heading { text: "02  DISPOSITIVOS" }

            Label {
                visible: pairedList.count === 0
                text: "SIN DISPOSITIVOS EMPAREJADOS"
            }

            ListView {
                id: pairedList
                width: parent.width
                height: Math.min(contentHeight, root.maxRows * (root.rowHeight + spacing))
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Bt.paired
                delegate: DeviceRow {}
            }
        }

        // Búsqueda de dispositivos nuevos
        Column {
            width: parent.width
            spacing: 10
            visible: Bt.enabled

            Item {
                width: parent.width
                height: scan.height

                Heading {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "03  BUSCAR"
                }

                PillButton {
                    id: scan
                    anchors.right: parent.right
                    label: Bt.adapter?.discovering ? "BUSCANDO…" : "BUSCAR"
                    dotColor: Bt.adapter?.discovering ? Theme.highlight : Theme.muted
                    onClicked: Bt.adapter.discovering = !Bt.adapter.discovering
                }
            }

            Label {
                visible: (Bt.adapter?.discovering ?? false) && newList.count === 0
                text: "BUSCANDO DISPOSITIVOS…"
            }

            ListView {
                id: newList
                width: parent.width
                height: Math.min(contentHeight, root.maxRows * (root.rowHeight + spacing))
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Bt.discovered
                delegate: DeviceRow {}
            }
        }

        Label {
            visible: !Bt.enabled
            text: "ENCIÉNDELO PARA VER Y CONECTAR DISPOSITIVOS"
        }
    }
}
