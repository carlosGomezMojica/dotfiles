import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

// Tarjeta del panel de batería: nivel, salud y perfil de energía
Rectangle {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property real level: device.percentage   // 0..1
    readonly property bool charging: device.state === UPowerDeviceState.Charging
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged
    readonly property color levelColor: level <= 0.2 ? Theme.error
                                      : level <= 0.4 ? Theme.warning
                                      : Theme.success
    // La salud y los ciclos solo los reporta la batería física, no el dispositivo agregado
    readonly property var battery: UPower.devices.values.find(d => d.isLaptopBattery) ?? null
    // healthPercentage viene en 0..100
    readonly property real health: battery?.healthSupported ? battery.healthPercentage : 0

    readonly property int padding: 20
    readonly property real contentWidth: width - padding * 2

    function formatTime(seconds) {
        const h = Math.floor(seconds / 3600)
        const m = Math.round((seconds % 3600) / 60)
        return h > 0 ? h + "H " + m + "M" : m + "M"
    }

    function reloadCycles() { cycles.reload() }

    implicitWidth: 300
    implicitHeight: column.implicitHeight + padding * 2
    radius: 16
    color: Theme.bg   // mismo fondo que la cápsula de la barra
    border.width: 1
    border.color: Theme.panelBorder

    // Quickshell no expone los ciclos de carga
    FileView {
        id: cycles
        path: "/sys/class/power_supply/" + (root.battery?.nativePath || "BAT0") + "/cycle_count"
    }

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

    Column {
        id: column
        x: root.padding
        y: root.padding
        width: root.contentWidth
        spacing: 18

        // Cabecera
        Item {
            width: parent.width
            height: statePill.height

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "01  BATERÍA"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 11
                font.letterSpacing: 1.5
            }

            StatusPill {
                id: statePill
                anchors.right: parent.right
                label: root.charging ? "CARGANDO" : root.full ? "LLENA" : "DESCARGANDO"
                dotColor: root.charging ? Theme.warning : root.full ? Theme.success : root.levelColor
                borderColor: root.charging ? Theme.warning : Theme.panelBorder
                textColor: root.charging ? Theme.warning : Theme.text
            }
        }

        // Anillo con el porcentaje
        Item {
            width: parent.width
            height: 150

            DotRing {
                id: ring
                anchors.centerIn: parent
                width: 150
                height: 150
                level: root.level
                // Cargando: anillo en verde y el punto hasta donde va la carga en naranja
                onColor: root.charging ? Theme.success : root.levelColor
                leadColor: root.charging ? Theme.warning : root.levelColor
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        text: Math.round(root.level * 100)
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 40
                        font.weight: Font.Light
                    }

                    Text {
                        anchors.baseline: parent.children[0].baseline
                        text: "%"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 16
                    }
                }

                // Tiempo estimado en dos líneas para que quepa dentro del anillo
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text !== ""
                    text: root.charging && root.device.timeToFull > 0
                              ? root.formatTime(root.device.timeToFull)
                        : !root.charging && !root.full && root.device.timeToEmpty > 0
                              ? root.formatTime(root.device.timeToEmpty)
                        : ""
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 11
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.charging ? "PARA LLENAR"
                        : root.full ? "COMPLETA"
                        : root.device.timeToEmpty > 0 ? "RESTANTES"
                        : "CALCULANDO…"
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
                Label { text: "SALUD" }
                Value { text: root.health > 0 ? Math.round(root.health) + "%" : "—" }
                Label {
                    visible: root.health > 0
                    text: root.device.energyCapacity.toFixed(1) + " / "
                          + (root.device.energyCapacity / (root.health / 100)).toFixed(1) + " Wh"
                    font.pixelSize: 8
                }
            }

            Rectangle { width: 1; height: 44; color: Theme.panelBorder }

            Column {
                width: stats.cell
                spacing: 4
                leftPadding: 12
                Label { text: "CICLOS" }
                Value { text: cycles.text().trim() || "—" }
            }

            Rectangle { width: 1; height: 44; color: Theme.panelBorder }

            Column {
                width: stats.cell
                spacing: 4
                leftPadding: 12
                Label { text: root.charging ? "ENTRADA" : "CONSUMO" }
                Value { text: Math.abs(root.device.changeRate).toFixed(1) + " W" }
            }
        }

        // Perfil de energía
        Column {
            width: parent.width
            spacing: 10

            Text {
                text: "02  PERFIL"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 11
                font.letterSpacing: 1.5
            }

            Row {
                id: profiles
                width: parent.width
                spacing: 8

                readonly property var options: [
                    { profile: PowerProfile.PowerSaver,  label: "AHORRO",      icon: 0xF032A },  // nf-md-leaf
                    { profile: PowerProfile.Balanced,    label: "EQUILIBRADO", icon: 0xF05D1 },  // nf-md-scale_balance
                    { profile: PowerProfile.Performance, label: "RENDIMIENTO", icon: 0xF04C5 }   // nf-md-speedometer
                ].filter(o => o.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

                Repeater {
                    model: profiles.options

                    delegate: Rectangle {
                        id: option
                        required property var modelData
                        readonly property bool active: PowerProfiles.profile === modelData.profile

                        width: (profiles.width - profiles.spacing * (profiles.options.length - 1)) / profiles.options.length
                        height: 58
                        radius: 12
                        color: active ? Qt.alpha(Theme.accent, 0.08) : "transparent"
                        border.width: 1
                        border.color: active ? Theme.accent : Theme.panelBorder

                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: String.fromCodePoint(option.modelData.icon)
                                color: option.active ? Theme.accent : Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 18
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: option.modelData.label
                                color: option.active ? Theme.text : Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 8
                                font.letterSpacing: 1
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerProfiles.profile = option.modelData.profile
                        }
                    }
                }
            }
        }
    }
}
