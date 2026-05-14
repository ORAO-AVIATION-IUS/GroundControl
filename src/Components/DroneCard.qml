import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string droneId: "M1"
    property string flightMode: "STBY"
    property bool armed: false
    property bool selected: false
    property double pitch: 0
    property double roll: 0
    property double altitude: 0
    property double groundspeed: 0
    property int battery: 100
    property int gpsCount: 0
    property int gpsFix: 0   // 0=no fix  1=2D  2=3D
    property bool sysHealth: true

    signal armRequested()
    signal disarmRequested()
    signal selectRequested()

    color: selected ? "#131e30" : "#0c1522"
    border.color: selected ? "#2f5fcc" : (armed ? "#1d5535" : "#172333")
    border.width: selected ? 2 : 1
    radius: 8

    MouseArea {
        anchors.fill: parent
        onClicked: root.selectRequested()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Rectangle {
                width: 8; height: 8; radius: 4
                color: root.armed ? "#00dd66" : "#cc3333"
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Text {
                text: root.droneId
                color: "#cce0ff"
                font.pixelSize: 12
                font.bold: true
                font.family: "Courier New"
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                height: 14
                width: modeLabel.implicitWidth + 10
                radius: 3
                color: "#060e1a"
                border.color: "#1b2d42"
                border.width: 1

                Text {
                    id: modeLabel
                    anchors.centerIn: parent
                    text: root.flightMode
                    color: "#4d7faa"
                    font.pixelSize: 8
                    font.bold: true
                    font.family: "Courier New"
                }
            }

            // sys-health dot: blue=ok  red=fault
            Rectangle {
                width: 6; height: 6; radius: 3
                color: root.sysHealth ? "#2266dd" : "#dd3311"
                opacity: 0.85
            }
        }

        AttitudeIndicator {
            Layout.alignment: Qt.AlignHCenter
            width: Math.min(root.width - 16, 96)
            height: width
            pitch: root.pitch
            roll: root.roll
        }

        Grid {
            Layout.fillWidth: true
            columns: 4
            spacing: 2

            Text { text: "ALT"; color: "#2e4d66"; font.pixelSize: 8 }
            Text {
                text: root.altitude.toFixed(0) + "m"
                color: "#7aaac8"; font.pixelSize: 8
                width: (root.width - 28) / 2; elide: Text.ElideRight
            }
            Text { text: "SPD"; color: "#2e4d66"; font.pixelSize: 8 }
            Text { text: root.groundspeed.toFixed(1) + "m/s"; color: "#7aaac8"; font.pixelSize: 8 }

            Text { text: "BAT"; color: "#2e4d66"; font.pixelSize: 8 }
            Text {
                text: root.battery + "%"
                color: root.battery > 50 ? "#2db36a" : root.battery > 20 ? "#e0960a" : "#dd3322"
                font.pixelSize: 8
            }
            Text { text: "GPS"; color: "#2e4d66"; font.pixelSize: 8 }
            Text {
                text: root.gpsCount + (root.gpsFix === 2 ? "/3D" : root.gpsFix === 1 ? "/2D" : "/--")
                color: root.gpsFix === 2 ? "#2db36a" : root.gpsFix === 1 ? "#e0960a" : "#dd3322"
                font.pixelSize: 8
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                height: 20; radius: 3
                color: armArea.pressed  ? "#004d1e"
                     : armArea.containsMouse ? "#003815" : "#00210d"
                border.color: root.armed ? "#111" : "#007a3d"
                border.width: 1
                opacity: root.armed ? 0.3 : 1.0

                Text {
                    anchors.centerIn: parent
                    text: "ARM"; color: "#00e86e"
                    font.pixelSize: 9; font.bold: true; font.family: "Courier New"
                }

                MouseArea {
                    id: armArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !root.armed
                    onClicked: (mouse) => { mouse.accepted = true; root.armRequested() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 20; radius: 3
                color: disarmArea.pressed  ? "#4d1400"
                     : disarmArea.containsMouse ? "#380e00" : "#220800"
                border.color: root.armed ? "#aa2d00" : "#111"
                border.width: 1
                opacity: root.armed ? 1.0 : 0.3

                Text {
                    anchors.centerIn: parent
                    text: "DISARM"; color: "#ff6022"
                    font.pixelSize: 9; font.bold: true; font.family: "Courier New"
                }

                MouseArea {
                    id: disarmArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.armed
                    onClicked: (mouse) => { mouse.accepted = true; root.disarmRequested() }
                }
            }
        }
    }
}
