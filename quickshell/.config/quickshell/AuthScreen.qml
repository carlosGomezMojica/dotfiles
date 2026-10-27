import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects

// Pantalla de autenticación compartida por el bloqueo (Lock.qml, mode "lock") y el inicio
// de sesión (greeter.qml, mode "greeter"): wallpaper desenfocado, reloj grande, tarjeta con
// avatar y contraseña, estado del sistema, energía y (bloqueo) lo que suena.
// No autentica: emite `submit(user, password)` y quien la usa responde con `fail()` / `busy`.
Item {
    id: root

    property string mode: "lock"
    property string user: ""
    // Foto del usuario (vacía: la inicial)
    property string avatar: ""
    property bool busy: false
    // Greeter: sesiones [{ name, command: [] }] y la elegida
    property var sessions: []
    property int sessionIndex: 0

    signal submit(string user, string password)

    // Contraseña incorrecta: tiembla la tarjeta y se avisa
    function fail(message) {
        busy = false
        error = message || "CONTRASEÑA INCORRECTA"
        password.text = ""
        shake.restart()
        password.forceActiveFocus()
    }

    function focusInput() { (userEdit.visible ? userEdit : password).forceActiveFocus() }

    property string error: ""

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    component Label: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 9
        font.letterSpacing: 1.5
    }

    // Botón de energía: icono que pide un segundo clic para confirmar
    component PowerButton: Rectangle {
        id: button
        property string glyph
        property string label
        property var command: []
        property bool confirm: true
        property bool armed: false

        width: 44
        height: 44
        radius: 22
        color: Qt.alpha(Theme.bg, 0.55)
        border.width: 1
        border.color: armed ? Theme.error : area.containsMouse ? Theme.highlight : Theme.panelBorder

        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: button.glyph
            color: button.armed ? Theme.error : area.containsMouse ? Theme.highlight : Theme.text
            font.family: Theme.font
            font.pixelSize: 18
        }

        // Pista bajo el botón cuando está armado
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 6
            visible: button.armed
            text: "¿" + button.label + "?"
            color: Theme.error
        }

        Timer { id: disarm; interval: 3000; onTriggered: button.armed = false }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (button.confirm && !button.armed) { button.armed = true; disarm.restart(); return }
                button.armed = false
                Quickshell.execDetached(button.command)
            }
        }
    }

    // --- Fondo: wallpaper desenfocado y velo ---
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Theme.wallpaper !== "" ? "file://" + Theme.wallpaper : ""
        sourceSize: Qt.size(root.width / 2, root.height / 2)   // se desenfoca: no hace falta más
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        saturation: 0.1
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, 0.35)
    }

    // --- Reloj: cristal con la hora grande y la fecha ---
    Rectangle {
        id: clockPanel
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.12
        width: clockColumn.implicitWidth + 96
        height: clockColumn.implicitHeight + 48
        radius: 28
        color: Qt.alpha(Theme.bg, 0.45)
        border.width: 1
        border.color: Qt.alpha(Theme.text, 0.12)

        Column {
            id: clockColumn
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 128
                font.weight: Font.Light
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    const s = clock.date.toLocaleDateString(Qt.locale(), "dddd d 'de' MMMM")
                    return s.charAt(0).toUpperCase() + s.slice(1)
                }
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 18
            }
        }
    }

    // --- Estado del sistema (arriba a la derecha) ---
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 8

        readonly property var battery: UPower.displayDevice

        StatusPill {
            visible: parent.battery.isLaptopBattery
            readonly property bool charging: parent.battery.state === UPowerDeviceState.Charging
            label: (charging ? "CARGANDO " : "BATERÍA ") + Math.round(parent.battery.percentage * 100) + "%"
            dotColor: charging ? Theme.warning : parent.battery.percentage <= 0.2 ? Theme.error : Theme.success
            color: Qt.alpha(Theme.bg, 0.55)
        }

        StatusPill {
            label: Net.wired ? "CABLE" : Net.current ? Net.current.name.toUpperCase() : "SIN RED"
            dotColor: Net.stateColor
            color: Qt.alpha(Theme.bg, 0.55)
        }

        StatusPill {
            label: "DVORAK"
            dotColor: Theme.accent
            color: Qt.alpha(Theme.bg, 0.55)
        }
    }

    // --- Tarjeta: avatar, usuario y contraseña ---
    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: shakeOffset
        y: Math.max(clockPanel.y + clockPanel.height + 48, root.height * 0.5 - height / 2 + 40)
        width: 340
        height: cardColumn.implicitHeight + 48
        radius: 20
        color: Qt.alpha(Theme.bg, 0.78)
        border.width: 1
        border.color: root.error !== "" ? Theme.error : Theme.panelBorder

        property real shakeOffset: 0

        Behavior on border.color { ColorAnimation { duration: 150 } }

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: card; property: "shakeOffset"; to: -14; duration: 50 }
            NumberAnimation { target: card; property: "shakeOffset"; to: 12; duration: 60 }
            NumberAnimation { target: card; property: "shakeOffset"; to: -8; duration: 60 }
            NumberAnimation { target: card; property: "shakeOffset"; to: 5; duration: 60 }
            NumberAnimation { target: card; property: "shakeOffset"; to: 0; duration: 50 }
        }

        Column {
            id: cardColumn
            anchors.horizontalCenter: parent.horizontalCenter
            y: 24
            width: parent.width - 48
            spacing: 14

            // Avatar circular (foto o inicial)
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 76
                height: 76

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.surface
                    border.width: 2
                    border.color: Theme.accent

                    Text {
                        anchors.centerIn: parent
                        visible: !avatarImage.ready
                        text: (root.user || "?").charAt(0).toUpperCase()
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 32
                    }
                }

                CoverArt {
                    id: avatarImage
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: width / 2
                    source: root.avatar
                    // Sin foto (o sin ~/.face): se queda la inicial
                    opacity: ready ? 1 : 0
                }
            }

            // Usuario: en el greeter, clic para escribir otro
            Item {
                width: parent.width
                height: 24

                Text {
                    id: userName
                    anchors.centerIn: parent
                    visible: !userEdit.visible
                    text: root.user || "Usuario"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 16

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.mode === "greeter"
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            userEdit.text = root.user
                            userEdit.visible = true
                            userEdit.forceActiveFocus()
                            userEdit.selectAll()
                        }
                    }
                }

                TextInput {
                    id: userEdit
                    anchors.centerIn: parent
                    width: parent.width
                    visible: false
                    horizontalAlignment: TextInput.AlignHCenter
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 16
                    onAccepted: {
                        if (text.trim() !== "") root.user = text.trim()
                        visible = false
                        password.forceActiveFocus()
                    }
                    Keys.onEscapePressed: { visible = false; password.forceActiveFocus() }
                }
            }

            // Contraseña
            Rectangle {
                width: parent.width
                height: 44
                radius: 12
                color: "transparent"
                border.width: 1
                border.color: root.error !== "" ? Theme.error
                            : password.activeFocus ? Theme.accent
                            : Theme.panelBorder

                Behavior on border.color { ColorAnimation { duration: 150 } }

                MouseArea { anchors.fill: parent; onClicked: password.forceActiveFocus() }

                TextInput {
                    id: password
                    anchors.verticalCenter: parent.verticalCenter
                    x: 16
                    width: parent.width - 32
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: Theme.text
                    selectionColor: Qt.alpha(Theme.accent, 0.35)
                    font.family: Theme.font
                    font.pixelSize: 16
                    font.letterSpacing: 2
                    clip: true
                    focus: true
                    enabled: !root.busy

                    cursorDelegate: Rectangle { width: 2; color: Theme.accent }

                    onTextChanged: if (text !== "") root.error = ""

                    Text {
                        visible: password.text === ""
                        text: root.busy ? "Verificando…" : "Contraseña"
                        color: Theme.surface
                        font.family: Theme.font
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (text === "" || root.busy) return
                            root.busy = true
                            root.error = ""
                            root.submit(root.user, text)
                        } else if (event.key === Qt.Key_Escape) {
                            text = ""
                        } else return
                        event.accepted = true
                    }
                }
            }

            // Estado: verificando o error
            Item {
                width: parent.width
                height: statePill.height

                StatusPill {
                    id: statePill
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.busy || root.error !== ""
                    label: root.busy ? "VERIFICANDO…" : root.error
                    dotColor: root.busy ? Theme.highlight : Theme.error
                    borderColor: root.busy ? Theme.panelBorder : Theme.error
                    textColor: root.busy ? Theme.text : Theme.error
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !statePill.visible
                    text: root.mode === "lock" ? "SESIÓN BLOQUEADA · ENTER PARA DESBLOQUEAR" : "ENTER PARA INICIAR SESIÓN"
                }
            }
        }
    }

    // --- Abajo a la izquierda: lo que suena (bloqueo) o la sesión (greeter) ---
    Loader {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        active: root.mode === "lock"
        sourceComponent: NowPlaying {}
    }

    StatusPill {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32
        visible: root.mode === "greeter" && root.sessions.length > 0
        label: "SESIÓN · " + (root.sessions[root.sessionIndex]?.name ?? "").toUpperCase()
        dotColor: Theme.accent
        color: Qt.alpha(Theme.bg, 0.55)

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length
        }
    }

    // --- Abajo a la derecha: energía ---
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32
        spacing: 12

        PowerButton {
            glyph: String.fromCodePoint(0xF04B2)   // nf-md-power_sleep
            label: "SUSPENDER"
            command: ["systemctl", "suspend"]
            confirm: root.mode !== "lock"
        }

        PowerButton {
            glyph: String.fromCodePoint(0xF0709)   // nf-md-restart
            label: "REINICIAR"
            command: ["systemctl", "reboot"]
        }

        PowerButton {
            glyph: String.fromCodePoint(0xF0425)   // nf-md-power
            label: "APAGAR"
            command: ["systemctl", "poweroff"]
        }
    }
}
