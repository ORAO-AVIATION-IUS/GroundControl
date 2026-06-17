pragma ComponentBehavior: Bound

import Agc.Camera
import Agc.Style as S
import QtMultimedia
import QtQuick
import QtQuick.Controls

Item {
	id: root

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
		color: S.Style.bgWindow
		visible: !root.connected

		Column {
			anchors.centerIn: parent
			spacing: 8

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: root.statusText || qsTr("No stream connected")
				color: S.Style.textMuted
				font.pixelSize: 14
				font.family: S.Style.fontFamily
			}

			Button {
				anchors.horizontalCenter: parent.horizontalCenter
				text: qsTr("Reconnect")
				visible: root.statusText !== ""
				onClicked: CameraManager.reconnectStream(root.streamId)
			}
		}
	}

	Connections {
		target: CameraManager

		function onStreamConnectedChanged(id, connected) {
			if (id === root.streamId)
				root.connected = connected;
		}

		function onStreamStatusChanged(id, status) {
			if (id === root.streamId)
				root.statusText = status;
		}
	}

	Component.onCompleted: {
		CameraManager.attachSink(streamId, video.videoSink);
		root.connected = CameraManager.streamConnected(streamId);
		root.statusText = CameraManager.streamStatus(streamId);
	}
}
