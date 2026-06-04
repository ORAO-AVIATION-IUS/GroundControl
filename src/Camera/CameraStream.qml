pragma ComponentBehavior: Bound
import Agc.Camera
import QtMultimedia
import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property int streamId
    property bool connected: false
    property string statusText: ""
    property var detections: []
    property bool detectionEnabled: true

    anchors.fill: parent

    VideoOutput {
        id: video
        anchors.fill: parent
    }

    // Detection overlay
    Repeater {
        model: root.detections

        delegate: Item {
            required property var modelData

            x: video.contentRect.x + modelData.x * video.contentRect.width
            y: video.contentRect.y + modelData.y * video.contentRect.height
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
                    text: "%1 %2%".arg(modelData.label)
                                  .arg(Math.round(modelData.score * 100))
                    color: "#00FF41"
                    font.pixelSize: 11
                    font.family: "Monospace"
                }
            }
        }
    }

    // No-signal overaly
    Rectangle {
        anchors.fill: parent
        color: "#14141e"
        visible: !root.connected

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.statusText || "No stream connected"
                color: "#888"
                font.pixelSize: 14
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Reconnect")
                visible: root.statusText !== ""
                onClicked: CameraManager.reconnectStream(root.streamId)
            }
        }
    }

    // conn signals
    Connections {
        target: CameraManager

        function onStreamConnectedChanged(id, connected) {
            if (id === root.streamId)
                root.connected = connected
        }
        function onStreamStatusChanged(id, status) {
            if (id === root.streamId)
                root.statusText = status
        }
        function onDetectionsChanged(id, dets) {
            if (id === root.streamId)
                root.detections = dets
        }
    }

    Component.onCompleted: {
        CameraManager.attachSink(streamId, video.videoSink)
        root.connected = CameraManager.streamConnected(streamId)
        root.statusText = CameraManager.streamStatus(streamId)

        if (root.detectionEnabled)
            CameraManager.setDetectionEnabled(streamId, true)
    }

    Component.onDestruction: {
        CameraManager.setDetectionEnabled(streamId, false)
    }
}