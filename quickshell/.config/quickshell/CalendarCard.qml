import Quickshell
import QtQuick

// Tarjeta del panel de calendario: hoy, mes navegable y lo que queda del año
Rectangle {
    id: root

    readonly property date now: clock.date
    // Mes mostrado (cualquier día de ese mes); vuelve a hoy al abrir el panel
    property date shown: new Date()

    // Lo que queda del año (0..1) y en días
    readonly property real yearLeft: {
        const start = new Date(now.getFullYear(), 0, 1)
        const end = new Date(now.getFullYear() + 1, 0, 1)
        return (end - now) / (end - start)
    }
    readonly property int daysLeft: Math.ceil((new Date(now.getFullYear() + 1, 0, 1) - now) / 86400000)

    // Semanas necesarias (4-6), empezando en lunes: { day, current (del mes mostrado), today }
    readonly property var cells: {
        const y = shown.getFullYear(), m = shown.getMonth()
        const offset = (new Date(y, m, 1).getDay() + 6) % 7   // lunes = 0
        const days = new Date(y, m + 1, 0).getDate()
        const total = Math.ceil((offset + days) / 7) * 7
        const list = []
        for (let i = 0; i < total; i++) {
            const d = new Date(y, m, 1 - offset + i)
            list.push({
                day: d.getDate(),
                current: d.getMonth() === m,
                today: d.toDateString() === now.toDateString()
            })
        }
        return list
    }

    readonly property int padding: 20

    function resetMonth() { shown = new Date() }
    function moveMonth(delta) { shown = new Date(shown.getFullYear(), shown.getMonth() + delta, 1) }

    // Semana ISO 8601
    function isoWeek(d) {
        const t = new Date(d.getFullYear(), d.getMonth(), d.getDate())
        t.setDate(t.getDate() + 3 - (t.getDay() + 6) % 7)   // jueves de esa semana
        const firstThursday = new Date(t.getFullYear(), 0, 4)
        return 1 + Math.round(((t - firstThursday) / 86400000 - 3 + (firstThursday.getDay() + 6) % 7) / 7)
    }

    function capitalize(s) { return s.charAt(0).toUpperCase() + s.slice(1) }

    implicitWidth: 300
    implicitHeight: column.implicitHeight + padding * 2
    radius: 16
    color: Theme.bg
    border.width: 1
    border.color: Theme.panelBorder

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
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

    component Heading: Text {
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 11
        font.letterSpacing: 1.5
    }

    // Flecha clicable para cambiar de mes
    component Arrow: Text {
        id: arrow
        signal clicked()
        color: arrowArea.containsMouse ? Theme.accent : Theme.muted
        font.family: Theme.font
        font.pixelSize: 16

        MouseArea {
            id: arrowArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: arrow.clicked()
        }
    }

    Column {
        id: column
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 18

        // Hoy
        Column {
            width: parent.width
            spacing: 10

            Item {
                width: parent.width
                height: timePill.height

                Heading {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "01  HOY"
                }

                StatusPill {
                    id: timePill
                    anchors.right: parent.right
                    label: Qt.formatTime(root.now, "HH:mm")
                    dotColor: Theme.accent
                }
            }

            Column {
                spacing: 2

                Value {
                    text: root.capitalize(root.now.toLocaleDateString(Qt.locale(), "dddd"))
                    font.pixelSize: 22
                }

                Label {
                    text: root.now.toLocaleDateString(Qt.locale(), "d 'de' MMMM 'de' yyyy").toUpperCase()
                }
            }
        }

        // Mes
        Column {
            width: parent.width
            spacing: 10

            Item {
                width: parent.width
                height: monthTitle.height

                Heading {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "02  CALENDARIO"
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Arrow {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF0141)   // nf-md-chevron_left
                        onClicked: root.moveMonth(-1)
                    }

                    // Clic en el mes: volver a hoy
                    StatusPill {
                        id: monthTitle
                        anchors.verticalCenter: parent.verticalCenter
                        label: root.shown.toLocaleDateString(Qt.locale(), "MMMM yyyy").toUpperCase()
                        dotColor: root.shown.getMonth() === root.now.getMonth()
                                  && root.shown.getFullYear() === root.now.getFullYear() ? Theme.accent : Theme.muted

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.resetMonth()
                        }
                    }

                    Arrow {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF0142)   // nf-md-chevron_right
                        onClicked: root.moveMonth(1)
                    }
                }
            }

            Grid {
                id: grid
                columns: 7
                width: parent.width
                readonly property real cell: width / 7

                // Iniciales de los días, empezando en lunes
                Repeater {
                    model: ["L", "M", "X", "J", "V", "S", "D"]

                    Item {
                        required property string modelData
                        width: grid.cell
                        height: 22

                        Label {
                            anchors.centerIn: parent
                            text: parent.modelData
                        }
                    }
                }

                Repeater {
                    model: root.cells

                    Item {
                        id: dayCell
                        required property var modelData
                        width: grid.cell
                        height: 32

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: 14
                            visible: dayCell.modelData.today
                            color: Qt.alpha(Theme.accent, 0.08)
                            border.width: 1
                            border.color: Theme.accent
                        }

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.modelData.day
                            color: dayCell.modelData.today ? Theme.accent
                                 : dayCell.modelData.current ? Theme.text
                                 : Theme.surface
                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        // Año
        Column {
            width: parent.width
            spacing: 10

            Heading { text: "03  AÑO " + root.now.getFullYear() }

            Row {
                width: parent.width
                spacing: 20

                Item {
                    width: 120
                    height: 120

                    DotRing {
                        anchors.fill: parent
                        level: root.yearLeft
                        onColor: Theme.accent
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                id: percent
                                text: Math.round(root.yearLeft * 100)
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 30
                                font.weight: Font.Light
                            }

                            Text {
                                anchors.baseline: percent.baseline
                                text: "%"
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 13
                            }
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "QUEDA"
                        }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Column {
                        spacing: 4
                        Label { text: "DÍAS RESTANTES" }
                        Value { text: root.daysLeft }
                    }

                    Column {
                        spacing: 4
                        Label { text: "SEMANA" }
                        Value { text: root.isoWeek(root.now) }
                    }
                }
            }
        }
    }
}
