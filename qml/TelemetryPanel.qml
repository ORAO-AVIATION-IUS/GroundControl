import QtQuick 2.6
import QtQuick.Controls 2.6
import QtQuick.Layouts 1.3

Rectangle {
    color: "#2c3e50"
    opacity: 0.8
    radius: 8
    border.color: "#34495e"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 8

        Text {
            text: "FLIGHT DATA"
            color: "#3498db"
            font.bold: true
            font.pixelSize: 18
        }


        TelemetryRow {
            label: "AIRSPEED:"
            value: mavManager.airspeed.toFixed(1) + " m/s"
        }

        // Yükseklik
        TelemetryRow {
            label: "ALTITUDE:"
            value: mavManager.altitude.toFixed(0) + " m"
        }

        // G-Kuvveti
        TelemetryRow {
            label: "G-FORCE:"
            value: mavManager.gForce.toFixed(2) + " G"
        }

        // Jiroskop (X ekseni)
        TelemetryRow {
            label: "GYRO X:"
            value: mavManager.gyroX.toFixed(2) + " rad/s"
        }
    }
}
