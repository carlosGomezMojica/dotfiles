import QtQuick

// Texto centrado en vertical por su dibujo y no por su caja: la caja incluye el espacio
// de descendentes y cada fuente (o glifo Nerd) tiene su propia línea base, así que con
// anchors.verticalCenter a secas números e iconos quedan a alturas distintas.
// `metricsText`: qué medir ("0123456789" para cifras; por defecto, el propio texto).
Text {
    id: root

    property string metricsText: text

    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: height / 2
        - (baselineOffset + metrics.tightBoundingRect.y + metrics.tightBoundingRect.height / 2)

    TextMetrics {
        id: metrics
        font: root.font
        text: root.metricsText
    }
}
