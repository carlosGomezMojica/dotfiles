import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Wayland
import QtQuick

// Inicio de sesión (greetd). No lo carga la shell normal: lo lanza el Hyprland del greeter
// (`quickshell -p /usr/share/quickshell-greeter/greeter.qml`, ver greeter/). El tema, la
// fuente y el wallpaper salen de QS_THEME_DIR (copia que mantiene `greeter-sync`).
ShellRoot {
    id: root

    readonly property string dataDir: "/var/lib/quickshell-greeter"
    // Último usuario que inició sesión (lo escribe greeter-sync)
    property string user: "withclay"
    property string avatar: ""
    property string password: ""
    property int sessionIndex: 0

    readonly property var sessions: [
        { name: "Hyprland (uwsm)", command: ["uwsm", "start", "-e", "-D", "Hyprland", "hyprland.desktop"] },
        { name: "Hyprland", command: ["start-hyprland"] }
    ]

    // Fallo: lo muestran todas las pantallas
    signal failed(string message)

    function login(user, password) {
        if (!Greetd.available) {
            failed("GREETD NO DISPONIBLE")
            return
        }
        root.user = user
        root.password = password
        Greetd.createSession(user)
    }

    Process {
        command: ["sh", "-c", 'cat "$1/user" 2>/dev/null; echo; test -f "$1/avatar.png" && printf "%s" "$1/avatar.png"', "sh", root.dataDir]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                if ((lines[0] || "").trim() !== "") root.user = lines[0].trim()
                root.avatar = (lines[1] || "").trim()
            }
        }
    }

    Connections {
        target: Greetd

        // greetd pide la contraseña (u otro dato): se responde con la escrita
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(root.password)
            else if (error) root.failed(message.toUpperCase())
        }

        function onAuthFailure(message) {
            root.password = ""
            root.failed("CONTRASEÑA INCORRECTA")
        }

        function onError(error) {
            root.password = ""
            root.failed("ERROR: " + error.toUpperCase())
        }

        // Autenticado: arrancar la sesión elegida y salir (el Hyprland del greeter se cierra
        // al terminar quickshell y greetd pasa a la sesión)
        function onReadyToLaunch() {
            root.password = ""
            Greetd.launch(root.sessions[root.sessionIndex].command, [], true)
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-greeter"
            // El teclado, en el primer monitor
            WlrLayershell.keyboardFocus: modelData === Quickshell.screens[0] ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            AuthScreen {
                id: screen
                anchors.fill: parent
                mode: "greeter"
                user: root.user
                avatar: root.avatar
                sessions: root.sessions
                sessionIndex: root.sessionIndex
                onSessionIndexChanged: root.sessionIndex = sessionIndex
                onSubmit: (user, password) => root.login(user, password)

                Component.onCompleted: Qt.callLater(focusInput)

                Connections {
                    target: root
                    function onFailed(message) { screen.fail(message) }
                }
            }
        }
    }
}
