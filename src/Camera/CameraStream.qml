import QtMultimedia
import QtQuick
import QtQuick.Controls

Item {
	id: root

	required property string playerId
	required property int streamId

	property bool connected: false
	property string statusText: ""

	anchors.fill: parent

	VideoOutput {
		id: video
		anchors.fill: parent
	}

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
				onClicked: cameraManager.reconnectStream(root.streamId)
			}
		}
	}

	Connections {
		target: cameraManager

		function onStreamConnectedChanged(id, connected) {
			if (id === root.streamId)
				root.connected = connected;
		}

		function onStreamStatusChanged(id, status) {
			if (id === root.streamId)
				root.statusText = status;
		}
	}

	Component.onCompleted: cameraManager.attachSink(streamId, video.videoSink)
}
