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
	property var detections: []
	property bool detectionEnabled: true

	anchors.fill: parent

	// A camera's frames are pushed to a single sink. When several CameraStream
	// instances can exist for the same camera (the standalone dock + the inline
	// drone-panel tab), the most-recently-shown one must (re)claim the sink, or
	// a hidden/destroyed instance keeps it and the visible one stays black.
	function claimSink() {
		if (root.streamId >= 0) {
			CameraManager.attachSink(root.streamId, video.videoSink);
			root.connected = CameraManager.streamConnected(root.streamId);
			root.statusText = CameraManager.streamStatus(root.streamId);
			if (root.detectionEnabled)
				CameraManager.setDetectionEnabled(root.streamId, true);
		}
	}

	onVisibleChanged: if (visible)
		claimSink()

	VideoOutput {
		id: video
		anchors.fill: parent
	}

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
				anchors.left: parent.left
				anchors.bottomMargin: 2
				color: "#CC000000"
				width: lbl.implicitWidth + 8
				height: lbl.implicitHeight + 4
				radius: 2

				Text {
					id: lbl
					anchors.centerIn: parent
					text: "%1 %2%".arg(modelData.label).arg(Math.round(modelData.score * 100))
					color: "#00FF41"
					font.pixelSize: 11
					font.family: S.Style.fontFamily
				}
			}
		}
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

		function onDetectionsChanged(id, dets) {
			if (id === root.streamId)
				root.detections = dets;
		}
	}

	Component.onCompleted: root.claimSink()

	Component.onDestruction: if (root.streamId >= 0)
		CameraManager.setDetectionEnabled(root.streamId, false)
}
