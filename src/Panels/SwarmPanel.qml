import Agc.Components
import QtQuick
import QtQuick.Layouts
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
    id: root
    uniqueName: "swarmPanel"
    title: qsTr("Drone Control")

    property string droneId:    "M1"
    property string flightMode: "STBY"
    property bool   armed:      false

    property real cpuLoad:    38.0
    property bool sensorImu:  true
    property bool sensorGps:  true
    property bool sensorBaro: true
    property bool sensorMag:  true

    property real roll:  0.0
    property real pitch: 0.0
    property real yaw:   0.0

    property real airspeed:    0.0
    property real groundspeed: 0.0
    property real climbRate:   0.0
    property int  throttle:    0
    property real heading:     0.0

    property real altRel: 0.0
    property real altMsl: 0.0

    property real voltage: 12.60
    property real current: 0.0
    property int  battery: 92

    property int  wpCurrent: 0
    property int  wpTotal:   8
    property real wpDist:    0.0

    property int ping: 45

    readonly property int    instSz:     82
    property  string         activeMode: "STBY"
    readonly  property bool  readyToFly: sensorImu && sensorGps && sensorBaro && sensorMag && battery > 20

    ListModel { id: logModel }

    function addLog(src, msg, level) {
        const lvl = (typeof level !== "undefined") ? level : "info"
        const d   = new Date()
        const ts  = String(d.getHours()).padStart(2, '0') + ":"
                  + String(d.getMinutes()).padStart(2, '0') + ":"
                  + String(d.getSeconds()).padStart(2, '0')
        logModel.insert(0, { "ts": ts, "src": src, "msg": msg, "level": lvl })
        if (logModel.count > 200)
            logModel.remove(200, logModel.count - 200)
    }

    function armDrone() {
        root.armed      = true
        root.flightMode = root.activeMode
        addLog(root.droneId, "Armed — motor check OK", "info")
    }

    function disarmDrone() {
        root.armed      = false
        root.flightMode = "STBY"
        root.activeMode = "STBY"
        addLog(root.droneId, "Disarmed", "info")
    }

    function setMode(mode) {
        root.activeMode = mode
        if (root.armed) {
            root.flightMode = mode
            addLog(root.droneId, "Mode changed to " + mode, "info")
        }
    }

    Component.onCompleted: {
        addLog("SYS", "Drone control initialized", "info")
        addLog("M1",  "Compass calibration required", "warn")
        addLog("M1",  "GPS 3D Fix — 12 satellites", "info")
        addLog("M1",  "Prearm checks passed", "info")
    }

    component TelRow: RowLayout {
        property string lbl:  ""
        property string val:  ""
        property bool   warn: false
        Layout.fillWidth: true
        spacing: 0
        Text {
            text: lbl
            color: "#9090a0"
            font.pixelSize: 10; font.family: "Segoe UI"
            Layout.preferredWidth: 46
        }
        Text {
            text: val
            Layout.fillWidth: true
            color: warn ? "#7a5a00" : "#1a1a2e"
            font.pixelSize: 10; font.family: "Segoe UI"
            horizontalAlignment: Text.AlignRight
        }
    }

    component ActBtn: Rectangle {
        property string label:    ""
        property color  bgColor:  "#f0f0f4"
        property color  txtColor: "#3a4a5a"
        signal tapped()
        Layout.fillWidth: true
        height: 26; radius: 0
        color: ma.pressed       ? Qt.darker(bgColor, 1.12)
             : ma.containsMouse ? Qt.darker(bgColor, 1.06) : bgColor
        border.color: Qt.darker(bgColor, 1.16); border.width: 1
        Text {
            anchors.centerIn: parent; text: label
            color: txtColor
            font.pixelSize: 11; font.bold: true; font.family: "Segoe UI"
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: parent.tapped() }
    }

    Rectangle {
        anchors.fill: parent
        color: "#ffffff"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true
                height: 44

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 0

                    Text {
                        text: root.droneId
                        font.pixelSize: 15; font.bold: true; font.family: "Segoe UI"
                        color: "#1a1a2e"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle { width: 1; height: 20; color: "#e4e4e8"; Layout.alignment: Qt.AlignVCenter; Layout.leftMargin: 12; Layout.rightMargin: 12 }

                    Text {
                        text: root.readyToFly ? "Ready To Fly" : "Not Ready"
                        font.pixelSize: 15; font.bold: true; font.family: "Segoe UI"
                        color: root.readyToFly ? "#1e7a40" : "#8a2010"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle { width: 1; height: 20; color: "#e4e4e8"; Layout.alignment: Qt.AlignVCenter; Layout.leftMargin: 12; Layout.rightMargin: 12 }

                    Text {
                        text: root.activeMode
                        font.pixelSize: 15; font.bold: true; font.family: "Segoe UI"
                        color: modeMa.containsMouse ? "#1a50a0" : "#344878"
                        Layout.alignment: Qt.AlignVCenter

                        MouseArea {
                            id: modeMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                const modes = ["STBY", "GUIDED", "AUTO", "RTL", "LOITER", "LAND"]
                                root.setMode(modes[(modes.indexOf(root.activeMode) + 1) % modes.length])
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 6
                        width: 76; height: 30; radius: 0
                        color: "#f6f8fa"
                        border.color: "#e0e4ea"; border.width: 1

                        Rectangle {
                            width: 3; height: parent.height; radius: 0
                            color: root.battery > 50 ? "#1e7a40"
                                 : root.battery > 20 ? "#c08000" : "#c02010"
                        }

                        Column {
                            anchors.left: parent.left; anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: "BATTERY"
                                font.pixelSize: 8; font.family: "Segoe UI"; color: "#9090a0"
                            }
                            Text {
                                text: root.battery + "%  " + root.voltage.toFixed(1) + " V"
                                font.pixelSize: 9; font.bold: true; font.family: "Segoe UI"
                                color: "#1a1a2e"
                            }
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 12
                        width: 76; height: 30; radius: 0
                        color: root.armed ? "#edf7f1" : "#f6f6f8"
                        border.color: root.armed ? "#8ecaaa" : "#dcdce4"; border.width: 1

                        Rectangle {
                            width: 3; height: parent.height; radius: 0
                            color: root.armed ? "#1e7a40" : "#c0c4cc"
                        }

                        Column {
                            anchors.left: parent.left; anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: "STATUS"
                                font.pixelSize: 8; font.family: "Segoe UI"; color: "#9090a0"
                            }
                            Text {
                                text: root.armed ? "ARMED" : "DISARMED"
                                font.pixelSize: 9; font.bold: true; font.family: "Segoe UI"
                                color: root.armed ? "#1a6030" : "#606878"
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1
                    color: "#e4e4e8"
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: "#ffffff"
                clip: true

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.preferredWidth: 150; Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 10
                            anchors.topMargin: 10; spacing: 3

                            Text {
                                text: "TELEMETRY"
                                color: "#a0a8b0"; font.pixelSize: 9; font.bold: true
                                font.letterSpacing: 1.4; font.family: "Segoe UI"
                                Layout.bottomMargin: 4
                            }

                            TelRow { lbl: "ROLL";  val: root.roll.toFixed(1)        + " °" }
                            TelRow { lbl: "PITCH"; val: root.pitch.toFixed(1)       + " °" }
                            TelRow { lbl: "YAW";   val: root.yaw.toFixed(1)         + " °" }
                            TelRow { lbl: "ALT";   val: root.altRel.toFixed(1)      + " m" }
                            TelRow { lbl: "CLIMB"; val: root.climbRate.toFixed(1)   + " m/s" }
                            TelRow { lbl: "GSPD";  val: root.groundspeed.toFixed(1) + " m/s" }
                            TelRow { lbl: "HDG";   val: root.heading.toFixed(1)     + " °" }
                            TelRow { lbl: "BAT";   val: root.battery                + " %";  warn: root.battery < 20 }
                            TelRow { lbl: "VOLT";  val: root.voltage.toFixed(2)     + " V";  warn: root.voltage < 11.0 }
                            TelRow { lbl: "PING";  val: root.ping                   + " ms"; warn: root.ping > 200 }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    Rectangle { width: 1; Layout.fillHeight: true; color: "#e8e8ec" }

                    Item {
                        Layout.preferredWidth: root.instSz * 3 + 16; Layout.fillHeight: true

                        GridLayout {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.topMargin: 10
                            columns: 3; rowSpacing: 6; columnSpacing: 6

                            AttitudeIndicator {
                                Layout.preferredWidth: root.instSz; Layout.preferredHeight: root.instSz
                                pitch: root.pitch; roll: root.roll
                            }
                            AirspeedIndicator {
                                Layout.preferredWidth: root.instSz; Layout.preferredHeight: root.instSz
                                airspeedMs: root.airspeed
                            }
                            TurnController {
                                Layout.preferredWidth: root.instSz; Layout.preferredHeight: root.instSz
                                yawspeed: root.yaw / 180.0
                                yacc:     root.roll / 30.0
                            }
                            CompassIndicator {
                                Layout.preferredWidth: root.instSz; Layout.preferredHeight: root.instSz
                                heading: root.heading
                            }
                            HeadingIndicator {
                                Layout.preferredWidth: root.instSz; Layout.preferredHeight: root.instSz
                                heading: root.heading
                            }

                            Rectangle {
                                Layout.preferredWidth: root.instSz; Layout.preferredHeight: root.instSz
                                color: "#f8f8fa"; radius: 0
                                border.color: "#e8e8ec"; border.width: 1
                                Column {
                                    anchors.centerIn: parent; spacing: 5
                                    BatteryIndicator {
                                        width: 54; height: 24
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.battery + "%"
                                        color: root.battery > 50 ? "#1e7a40"
                                             : root.battery > 20 ? "#7a5a00" : "#8a2010"
                                        font.pixelSize: 11; font.bold: true; font.family: "Segoe UI"
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.voltage.toFixed(2) + " V"
                                        color: "#9090a0"; font.pixelSize: 9; font.family: "Segoe UI"
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { width: 1; Layout.fillHeight: true; color: "#e8e8ec" }

                    Item {
                        Layout.preferredWidth: 230; Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 0

                            Text {
                                text: "CONTROLS"
                                color: "#a0a8b0"; font.pixelSize: 9; font.bold: true
                                font.letterSpacing: 1.4; font.family: "Segoe UI"
                                Layout.bottomMargin: 6
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2; rowSpacing: 3; columnSpacing: 3

                                ActBtn {
                                    label: "ARM"; bgColor: "#edf7f1"; txtColor: "#1a5830"
                                    enabled: !root.armed; opacity: root.armed ? 0.38 : 1.0
                                    onTapped: root.armDrone()
                                }
                                ActBtn {
                                    label: "DISARM"; bgColor: "#fdf0ee"; txtColor: "#6a1e1e"
                                    enabled: root.armed; opacity: root.armed ? 1.0 : 0.38
                                    onTapped: root.disarmDrone()
                                }
                                ActBtn {
                                    label: "TAKEOFF"; bgColor: "#edf2fa"; txtColor: "#1a3060"
                                    onTapped: root.addLog(root.droneId, "TAKEOFF command sent", "info")
                                }
                                ActBtn {
                                    label: "LAND"; bgColor: "#faf4ec"; txtColor: "#4a3010"
                                    onTapped: root.addLog(root.droneId, "LAND command sent", "info")
                                }
                                ActBtn {
                                    label: "RESET"; bgColor: "#f0f0f4"; txtColor: "#3a4a5a"
                                    onTapped: root.addLog(root.droneId, "RESET command sent", "warn")
                                }
                                ActBtn {
                                    label: "CONFIG"; bgColor: "#f0f0f4"; txtColor: "#3a4a5a"
                                    onTapped: root.addLog(root.droneId, "CONFIG command sent", "info")
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 1; color: "#e8e8ec"
                                Layout.topMargin: 10; Layout.bottomMargin: 10
                            }

                            Text {
                                text: "FLIGHT MODE"
                                color: "#a0a8b0"; font.pixelSize: 9; font.bold: true
                                font.letterSpacing: 1.4; font.family: "Segoe UI"
                                Layout.bottomMargin: 6
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2; rowSpacing: 3; columnSpacing: 3

                                Repeater {
                                    model: ["STBY", "GUIDED", "AUTO", "RTL", "LOITER", "LAND"]
                                    delegate: Rectangle {
                                        required property string modelData
                                        Layout.fillWidth: true; height: 26; radius: 0
                                        color: root.activeMode === modelData ? "#e8f0fa"
                                             : modeArea.containsMouse        ? "#f4f6fa" : "#f8f8fa"
                                        border.color: root.activeMode === modelData ? "#4070b0" : "#dcdce4"
                                        border.width: 1
                                        Text {
                                            anchors.centerIn: parent; text: modelData
                                            color: root.activeMode === modelData ? "#1a4890" : "#4a5060"
                                            font.pixelSize: 11
                                            font.bold: root.activeMode === modelData
                                            font.family: "Segoe UI"
                                        }
                                        MouseArea {
                                            id: modeArea; anchors.fill: parent; hoverEnabled: true
                                            onClicked: root.setMode(modelData)
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    Rectangle { width: 1; Layout.fillHeight: true; color: "#e8e8ec" }

                    Item {
                        Layout.fillWidth: true; Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 0

                            RowLayout {
                                Layout.fillWidth: true; Layout.bottomMargin: 6
                                Text {
                                    text: "STATUS LOG"
                                    color: "#a0a8b0"; font.pixelSize: 9; font.bold: true
                                    font.letterSpacing: 1.4; font.family: "Segoe UI"
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "CLR"
                                    color: clrArea.containsMouse ? "#3a4a5a" : "#b0b8c0"
                                    font.pixelSize: 9; font.family: "Segoe UI"
                                    MouseArea {
                                        id: clrArea; anchors.fill: parent; hoverEnabled: true
                                        onClicked: logModel.clear()
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#e8e8ec" }

                            ListView {
                                id: logView
                                Layout.fillWidth: true; Layout.fillHeight: true
                                model: logModel; clip: true; spacing: 2
                                Layout.topMargin: 6

                                delegate: RowLayout {
                                    required property string ts
                                    required property string src
                                    required property string msg
                                    required property string level
                                    width: logView.width; spacing: 5

                                    Text {
                                        text: ts; color: "#b0b8c4"
                                        font.pixelSize: 9; font.family: "Segoe UI"
                                    }
                                    Text {
                                        text: "[" + src + "]"; width: 36
                                        color: src === "SYS" ? "#2a5080" : "#6a4010"
                                        font.pixelSize: 9; font.bold: true; font.family: "Segoe UI"
                                    }
                                    Text {
                                        Layout.fillWidth: true; text: msg
                                        color: level === "err"  ? "#8a2010"
                                             : level === "warn" ? "#7a5a00" : "#4a5060"
                                        font.pixelSize: 9; font.family: "Segoe UI"
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
