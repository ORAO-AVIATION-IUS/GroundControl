pragma ComponentBehavior: Bound

import Agc.Camera
import Agc.Detection
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

	DetectionOverlay {
		anchors.fill: parent
		contentRect: video.contentRect
		detections: root.detections
	}

	DetectionAlertPanel {
		id: alertPanel
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		visible: root.detectionEnabled
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

		function onAlertChanged(id, alert) {
			if (id === root.streamId)
				alertPanel.addAlert(alert);
		}
	}

	Component.onCompleted: root.claimSink()

	Component.onDestruction: if (root.streamId >= 0)
		CameraManager.setDetectionEnabled(root.streamId, false)
}
