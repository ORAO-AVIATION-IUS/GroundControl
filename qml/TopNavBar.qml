import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: navbar
    width: parent.width
    height: 40
    color: "#2c3e50"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        spacing: 20

        Text {
            text: "ORAO"
            color: "#ecf0f1"
            font.pixelSize: 14
            font.bold: true
        }

        // Telemetri verisi (Mavlink bağlanınca burası güncellenecek)
        Text {
            id: pitchText
            text: "PITCH: 0.0°"
            color: "#2ecc71"
            font.pixelSize: 13
            font.family: "Monospace"
        }
    }
}
