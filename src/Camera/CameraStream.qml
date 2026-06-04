pragma ComponentBehavior: Bound
import Agc.Camera
import QtMultimedia
import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property int streamId
    property bool   connected:   false
    property string statusText:  ""
    property var    detections:  []
    property bool   detectionEnabled: true

    // Alert state
    property string currentAlert: ""
    property var    alertHistory: []  // list of {time, text}

    anchors.fill: parent

    VideoOutput {
        id: video
        anchors.fill: parent
    }

    // detections overlay
    Repeater {
        model: root.detections
        delegate: Item {
            required property var modelData
            x: video.contentRect.x + modelData.x * video.contentRect.width
            y:  video.contentRect.y + modelData.y * video.contentRect.height
            width: modelData.w * video.contentRect.width
            height: modelData.h * video.contentRect.height

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: "#00FF41"
                border.width: 2
                radius: 1
            }
            Rectangle {
                anchors.bottom: parent.top
                anchors.left:   parent.left
                anchors.bottomMargin: 2
                color:  "#CC000000"
                width:  lbl.implicitWidth + 8
                height: lbl.implicitHeight + 4
                radius: 2
                Text {
                    id: lbl
                    anchors.centerIn: parent
                    text:  "%1 %2%".arg(modelData.label)
                                   .arg(Math.round(modelData.score * 100))
                    color: "#00FF41"
                    font.pixelSize: 11
                    font.family:    "Monospace"
                }
            }
        }
    }

    // ai side panel
    Rectangle {
        id: bottomPanel
        anchors {
            left:   parent.left
            right:  parent.right
            bottom: parent.bottom
        }
        height:       expanded ? 180 : 36
        color:        "#CC0d0d14"
        border.color: "#2a2a3a"
        border.width: 1
        clip:         true

        property bool expanded: false

        Column {
            anchors {
                fill:    parent
                margins: 8
            }
            spacing: 6

            // Header
            Row {
                width:   parent.width
                height:  20
                spacing: 6

                // Status dot
                Rectangle {
                    width:  8; height: 8
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.currentAlert !== "" ? "#ff4444" : "#00FF41"

                    SequentialAnimation on opacity {
                        running:  root.currentAlert !== ""
                        loops:    Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 600 }
                        NumberAnimation { to: 1.0; duration: 600 }
                    }
                }

                Text {
                    text:  "AI ANALYSIS"
                    color: "#aaaacc"
                    font { pixelSize: 11; letterSpacing: 2; family: "Monospace" }
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Current alert — shown in header when collapsed
                Text {
                    visible: !bottomPanel.expanded
                    text: root.currentAlert !== "" ? root.currentAlert : "No anomalies detected"
                    color: root.currentAlert !== "" ? "#ff8888" : "#555566"
                    font: { pixelSize: 11; family: "Monospace" }
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 120
                }

                // Expand/collapse
                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text:  bottomPanel.expanded ? "▼ collapse" : "▲ history"
                    color: "#555577"
                    font { pixelSize: 10; family: "Monospace" }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    bottomPanel.expanded = !bottomPanel.expanded
                    }
                }
            }

            Rectangle {
                visible: bottomPanel.expanded
                width:   parent.width
                height:  1
                color:   "#2a2a3a"
            }

            // current alert red notif box
            Rectangle {
                visible: bottomPanel.expanded
                width:   parent.width
                height:  currentAlertText.implicitHeight + 12
                radius:  4
                color:        root.currentAlert !== "" ? "#33ff4444" : "#1a1a2a"
                border.color: root.currentAlert !== "" ? "#ff4444"   : "#2a2a3a"
                border.width: 1

                Text {
                    id: currentAlertText
                    anchors { fill: parent; margins: 6 }
                    text:     root.currentAlert !== "" ? root.currentAlert : "No anomalies detected"
                    color:    root.currentAlert !== "" ? "#ff8888" : "#555566"
                    font    { pixelSize: 12; family: "Monospace" }
                    wrapMode: Text.WordWrap
                }
            }

            // history view
            ListView {
                id:      historyList
                visible: bottomPanel.expanded
                width:   parent.width
                height:  bottomPanel.height - 36 - currentAlertText.implicitHeight - 38
                clip:    true
                model:   root.alertHistory
                spacing: 4

                orientation: ListView.Vertical

                delegate: Rectangle {
                    required property var modelData
                    width:  historyList.width
                    height: entryText.implicitHeight + timeText.implicitHeight + 12
                    color:  "#1a1a2a"
                    radius: 3

                    Text {
                        id: timeText
                        anchors { top: parent.top; left: parent.left; margins: 6 }
                        text:  modelData.time
                        color: "#444455"
                        font { pixelSize: 9; family: "Monospace" }
                    }
                    Text {
                        id: entryText
                        anchors {
                            top:     timeText.bottom
                            left:    parent.left
                            right:   parent.right
                            margins: 6
                        }
                        text:     modelData.text
                        color:    "#aaaacc"
                        font    { pixelSize: 11; family: "Monospace" }
                        wrapMode: Text.WordWrap
                    }
                }

                onCountChanged: positionViewAtEnd()
            }
        }
    }

    // no-signal overlay
    Rectangle {
        anchors.fill: parent
        color:   "#14141e"
        visible: !root.connected

        Column {
            anchors.centerIn: parent
            spacing: 8
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:  root.statusText || "No stream connected"
                color: "#888"
                font.pixelSize: 14
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text:    qsTr("Reconnect")
                visible: root.statusText !== ""
                onClicked: CameraManager.reconnectStream(root.streamId)
            }
        }
    }

    // conns
    Connections {
        target: CameraManager

        function onStreamConnectedChanged(id, connected) {
            if (id === root.streamId) root.connected = connected
        }
        function onStreamStatusChanged(id, status) {
            if (id === root.streamId) root.statusText = status
        }
        function onDetectionsChanged(id, dets) {
            if (id === root.streamId) root.detections = dets
        }
        function onAlertChanged(id, alert) {
            if (id !== root.streamId || alert === "") return

            root.currentAlert = alert

            // Prepend to history with timestamp
            const now = new Date()
            const time = now.getHours().toString().padStart(2,"0") + ":" +
                         now.getMinutes().toString().padStart(2,"0") + ":" +
                         now.getSeconds().toString().padStart(2,"0")

            let h = root.alertHistory.slice()  // copy to trigger binding
            h.unshift({ time: time, text: alert })
            if (h.length > 50) h = h.slice(0, 50)  // cap history
            root.alertHistory = h
        }
    }

    Component.onCompleted: {
        CameraManager.attachSink(streamId, video.videoSink)
        root.connected  = CameraManager.streamConnected(streamId)
        root.statusText = CameraManager.streamStatus(streamId)
        if (root.detectionEnabled)
            CameraManager.setDetectionEnabled(streamId, true)
    }

    Component.onDestruction: {
        CameraManager.setDetectionEnabled(streamId, false)
    }
}