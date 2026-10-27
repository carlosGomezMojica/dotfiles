import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Tarjeta de notificación con el estilo de los paneles (como BatteryCard)
Rectangle {
    id: root

    // Pasa a null durante la animación de salida (la notificación ya se destruyó)
    required property var notification
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    // Capturas de pantalla (script `captura`): la imagen va como vista previa ancha
    readonly property bool screenshot: (notification?.hints?.category ?? "") === "screenshot"
    readonly property color urgencyColor: critical ? Theme.error
        : notification?.urgency === NotificationUrgency.Low ? Theme.muted
        : Theme.accent
    readonly property var actions: Array.from(notification?.actions ?? []).filter(a => a.identifier !== "default")
    readonly property var defaultAction: Array.from(notification?.actions ?? []).find(a => a.identifier === "default") ?? null

    // Milisegundos hasta cerrarse sola: la app lo indica (-1 = por defecto, 0 = nunca); las críticas no caducan
    readonly property int timeout: critical || notification?.expireTimeout === 0 ? 0
        : notification?.expireTimeout > 0 ? notification?.expireTimeout
        : 5000
    property real remaining: timeout
    readonly property string time: Qt.formatTime(new Date(), "HH:mm")

    readonly property int padding: 16

    function iconSource(icon) {
        if (!icon) return ""
        return icon.startsWith("/") ? "file://" + icon
             : icon.includes("://") ? icon
             : Quickshell.iconPath(icon, true)
    }

    implicitWidth: 340
    implicitHeight: column.implicitHeight + padding * 2
    radius: 16
    color: Theme.bg
    border.width: 1
    border.color: critical ? Theme.error : hover.hovered ? Theme.highlight : Theme.panelBorder

    Behavior on border.color { ColorAnimation { duration: 120 } }

    // Cuenta atrás, en pausa mientras el ratón está encima
    Timer {
        interval: 50
        repeat: true
        running: root.timeout > 0 && !hover.hovered
        onTriggered: {
            root.remaining -= interval
            if (root.remaining <= 0) root.notification?.expire()
        }
    }

    HoverHandler { id: hover }

    // Clic en la tarjeta: acción por defecto (abrir la app) o descartar
    TapHandler {
        onTapped: {
            if (root.defaultAction) root.defaultAction.invoke()
            else root.notification?.dismiss()
        }
    }

    component Label: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 9
        font.letterSpacing: 1
    }

    Column {
        id: column
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 12

        // Cabecera: icono y nombre de la app, hora y cerrar
        Item {
            width: parent.width
            height: timePill.height

            // Hasta la hora: los nombres largos se recortan con «…» en vez de pisarla
            Row {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - headerRight.width - 12
                spacing: 8

                Image {
                    id: appIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    source: root.iconSource(root.notification?.appIcon || root.notification?.desktopEntry)
                    sourceSize: Qt.size(28, 28)
                    visible: status === Image.Ready
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - (appIcon.visible ? appIcon.width + parent.spacing : 0)
                    elide: Text.ElideRight
                    text: (root.notification?.appName || "Notificación").toUpperCase()
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.letterSpacing: 1.5
                }
            }

            Row {
                id: headerRight
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                StatusPill {
                    id: timePill
                    label: root.critical ? "URGENTE" : root.time
                    dotColor: root.urgencyColor
                    borderColor: root.critical ? Theme.error : Theme.panelBorder
                    textColor: root.critical ? Theme.error : Theme.text
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: String.fromCodePoint(0xF0156)   // nf-md-close
                    color: closeArea.containsMouse ? Theme.error : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 14

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notification?.dismiss()
                    }
                }
            }
        }

        // Captura: vista previa a todo el ancho, redondeada como las carátulas
        CoverArt {
            width: parent.width
            height: 150
            radius: 10
            visible: root.screenshot && source !== ""
            source: root.screenshot ? (root.notification?.image ?? "") : ""
        }

        // Imagen (si la hay), título y cuerpo
        Row {
            width: parent.width
            spacing: 12

            Image {
                id: image
                width: 44
                height: 44
                // Una ruta suelta (image-path) se tomaría por un nombre de icono
                source: (img => img.startsWith("/") ? "file://" + img : img)(root.notification?.image ?? "")
                sourceSize: Qt.size(88, 88)
                fillMode: Image.PreserveAspectCrop
                visible: !root.screenshot && source.toString() !== "" && status === Image.Ready
            }

            Column {
                width: parent.width - (image.visible ? image.width + parent.spacing : 0)
                spacing: 4

                Text {
                    width: parent.width
                    text: root.notification?.summary ?? ""
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.notification?.body ?? ""
                    textFormat: Text.StyledText
                    color: Theme.muted
                    linkColor: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
        }

        // Acciones como píldoras
        Flow {
            width: parent.width
            spacing: 6
            visible: root.actions.length > 0

            Repeater {
                model: root.actions

                StatusPill {
                    id: action
                    required property var modelData
                    label: modelData.text.toUpperCase()
                    dotColor: Theme.highlight
                    borderColor: actionArea.containsMouse ? Theme.highlight : Theme.panelBorder
                    textColor: actionArea.containsMouse ? Theme.highlight : Theme.text

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: action.modelData.invoke()
                    }
                }
            }
        }

        // Tiempo restante: línea fina que se vacía
        Rectangle {
            width: parent.width
            height: 2
            radius: 1
            color: Theme.surface
            visible: root.timeout > 0

            Rectangle {
                width: parent.width * Math.max(0, root.remaining / root.timeout)
                height: parent.height
                radius: 1
                color: root.urgencyColor
            }
        }
    }
}
