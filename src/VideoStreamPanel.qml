import QtQuick 2.6
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.15
import "qrc:/src/theme"
import gc 1.0

Rectangle {
    id: rootPanel
    color: '#ffffff'

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Header
        Text {
            text: qsTr("Video Stream")
            font.pixelSize: 16
            font.bold: true
            color: "#333333"
            Layout.fillWidth: true
        }

        // Connection type selector
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: qsTr("Source:")
                font.pixelSize: 12
            }

            ComboBox {
                id: sourceType
                model: ["RTSP", "UDP H.264", "Custom Pipeline"]
                Layout.fillWidth: true
                Layout.preferredHeight: Style.btnHeight + 4
            }
        }

        // URL / Pipeline input
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: sourceType.currentIndex === 0

            Text {
                text: qsTr("URL:")
                font.pixelSize: 12
            }

            TextField {
                id: rtspUrl
                Layout.fillWidth: true
                Layout.preferredHeight: Style.btnHeight + 4
                placeholderText: "rtsp://192.168.1.1:8554/live"
                text: "rtsp://192.168.1.1:8554/live"
                selectByMouse: true
                color: "#333333"
                background: Rectangle {
                    radius: Style.btnRadius
                    border.color: rtspUrl.activeFocus ? "#0e76ff" : "#cccccc"
                    border.width: 1
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: sourceType.currentIndex === 1

            Text {
                text: qsTr("Port:")
                font.pixelSize: 12
            }

            TextField {
                id: udpPort
                Layout.fillWidth: true
                Layout.preferredHeight: Style.btnHeight + 4
                placeholderText: "5600"
                text: "5600"
                selectByMouse: true
                color: "#333333"
                background: Rectangle {
                    radius: Style.btnRadius
                    border.color: udpPort.activeFocus ? "#0e76ff" : "#cccccc"
                    border.width: 1
                }
            }
        }

        TextField {
            id: customPipeline
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            visible: sourceType.currentIndex === 2
            placeholderText: " videotestsrc ! videoconvert ! video/x-raw,format=RGB ! appsink name=sink"
            selectByMouse: true
            wrapMode: TextInput.WordWrap
            color: "#333333"
            background: Rectangle {
                radius: Style.btnRadius
                border.color: customPipeline.activeFocus ? "#0e76ff" : "#cccccc"
                border.width: 1
            }
        }

        // Connect / Disconnect buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                id: connectBtn
                Layout.fillWidth: true
                Layout.preferredHeight: Style.btnHeight + 8
                color: connectMouse.pressed ? "#0a5fbf" : (connectMouse.containsMouse ? "#0e76ff" : "#1a8cff")
                radius: Style.btnRadius
                visible: !videoItem.connected

                Text {
                    anchors.centerIn: parent
                    text: qsTr("Connect")
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: connectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        var pipe = "";
                        if (sourceType.currentIndex === 0) {
                            pipe = "rtspsrc location=" + rtspUrl.text
                                + " latency=0 ! rtph264depay ! h264parse ! avdec_h264"
                                + " ! videoconvert ! video/x-raw,format=RGB ! appsink name=sink";
                        } else if (sourceType.currentIndex === 1) {
                            pipe = "udpsrc port=" + udpPort.text
                                + " caps=\"application/x-rtp,media=video,encoding-name=H264\""
                                + " ! rtph264depay ! h264parse ! avdec_h264"
                                + " ! videoconvert ! video/x-raw,format=RGB ! appsink name=sink";
                        } else {
                            pipe = customPipeline.text;
                        }
                        videoItem.pipeline = pipe;
                        videoItem.connectStream();
                    }
                }
            }

            Rectangle {
                id: disconnectBtn
                Layout.fillWidth: true
                Layout.preferredHeight: Style.btnHeight + 8
                color: disconnectMouse.pressed ? "#cc3333" : (disconnectMouse.containsMouse ? "#e04040" : "#ff4444")
                radius: Style.btnRadius
                visible: videoItem.connected

                Text {
                    anchors.centerIn: parent
                    text: qsTr("Disconnect")
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: disconnectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: videoItem.disconnectStream()
                }
            }

            // Test button (test pattern)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.btnHeight + 8
                color: testMouse.pressed ? Style.btnPressedColor : (testMouse.containsMouse ? Style.btnHoverColor : Style.btnColor)
                radius: Style.btnRadius

                Text {
                    anchors.centerIn: parent
                    text: qsTr("Test Pattern")
                    color: Style.btnTextColor
                    font.pixelSize: 11
                }

                MouseArea {
                    id: testMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        videoItem.pipeline = "videotestsrc pattern=ball ! videoconvert ! video/x-raw,format=RGB ! appsink name=sink";
                        videoItem.connectStream();
                    }
                }
            }
        }

        // Status bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            color: "#f0f0f0"
            radius: 3

            Text {
                anchors.centerIn: parent
                text: videoItem.status || "Ready"
                font.pixelSize: 10
                color: {
                    if (text.startsWith("Error")) return "#cc0000";
                    if (text === "Streaming") return "#008800";
                    return "#666666";
                }
            }
        }

        // Video display area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#141420"
            radius: 6
            border.color: "#333333"
            border.width: 1
            clip: true

            GStreamerVideoItem {
                id: videoItem
                anchors.fill: parent
                anchors.margins: 2
            }
        }
    }
}
