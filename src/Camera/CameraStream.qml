pragma ComponentBehavior: Bound

import Agc.Camera
import Agc.Components
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
	property bool showMenu: false

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
			root.detectionEnabled = CameraManager.detectionEnabled(root.streamId);
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
		detections: root.detectionEnabled ? root.detections : []
		visible: root.detectionEnabled
	}

	Rectangle {
		anchors.left: parent.left
		anchors.bottom: parent.bottom
		anchors.margins: 8
		visible: root.detectionEnabled
		width: countText.implicitWidth + 14
		height: 24
		radius: 4
		color: "#B0000000"
		border.color: "#3a3a46"
		border.width: 1

		Text {
			id: countText
			anchors.centerIn: parent
			text: qsTr("People: %1").arg(root.detections.length)
			color: "#ff4d4d"
			font.pixelSize: 12
			font.bold: true
			font.family: S.Style.fontFamily
		}
	}

	DetectionSettingsPopup {
		id: settingsPopup
		x: Math.max(8, root.width - width - 8)
		y: 42
		streamId: root.streamId
	}

	HamburgerMenu {
		visible: root.showMenu
		MenuItem {
			checkable: true
			checked: root.detectionEnabled
			text: qsTr("Human detection")
			onTriggered: CameraManager.setDetectionEnabled(root.streamId, checked)
		}
		MenuItem {
			text: qsTr("Detection adjustments…")
			onTriggered: settingsPopup.open()
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

		function onDetectionEnabledChanged(id, enabled) {
			if (id === root.streamId)
				root.detectionEnabled = enabled;
		}
	}

	Component.onCompleted: root.claimSink()
}
