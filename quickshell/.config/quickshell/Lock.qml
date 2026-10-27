import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

// Pantalla de bloqueo (ext-session-lock): AuthScreen en cada monitor y PAM (servicio
// "login") para la contraseña. `qs ipc call lock lock` (SUPER + L; hypridle al apagar la
// pantalla y antes de suspender).
Scope {
    id: root

    readonly property string user: Quickshell.env("USER")
    // Foto del usuario si existe ~/.face (si no, el avatar muestra la inicial)
    property string avatar: ""

    Process {
        command: ["sh", "-c", 'test -f "$HOME/.face" && printf "%s" "$HOME/.face"']
        running: true
        stdout: StdioCollector { onStreamFinished: root.avatar = text }
    }

    // Fallo de autenticación: lo muestran todas las superficies (una por monitor)
    signal failed(string message)

    function lock() { session.locked = true }

    function authenticate(password) {
        pam.pending = password
        if (!pam.active) pam.start()
        else if (pam.responseRequired) { pam.respond(password); pam.pending = "" }
    }

    PamContext {
        id: pam
        config: "login"
        user: root.user
        property string pending: ""

        // PAM pide la contraseña: se la damos
        onResponseRequiredChanged: if (responseRequired && pending !== "") { respond(pending); pending = "" }

        onCompleted: result => {
            if (result === PamResult.Success) session.locked = false
            else root.failed("CONTRASEÑA INCORRECTA")
        }
        onError: () => root.failed("ERROR DE AUTENTICACIÓN")
    }

    WlSessionLock {
        id: session

        WlSessionLockSurface {
            color: "black"

            AuthScreen {
                id: screen
                anchors.fill: parent
                mode: "lock"
                user: root.user
                avatar: root.avatar
                onSubmit: (user, password) => root.authenticate(password)

                Component.onCompleted: Qt.callLater(focusInput)

                Connections {
                    target: root
                    function onFailed(message) { screen.fail(message) }
                }
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock() }
    }
}
