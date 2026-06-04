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
	property string currentAlert: ""
	property var alertHistory: []

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
		id: bottomPanel
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		height: expanded ? 180 : 36
		color: "#CC0d0d14"
		border.color: "#2a2a3a"
		border.width: 1
		clip: true

		property bool expanded: false

		Column {
			anchors.fill: parent
			anchors.margins: 8
			spacing: 6

			Row {
				width: parent.width
				height: 20
				spacing: 6

				Rectangle {
					width: 8
					height: 8
					radius: 4
					anchors.verticalCenter: parent.verticalCenter
					color: root.currentAlert !== "" ? "#ff4444" : "#00FF41"

					SequentialAnimation on opacity {
						running: root.currentAlert !== ""
						loops: Animation.Infinite

						NumberAnimation {
							to: 0.2
							duration: 600
						}

						NumberAnimation {
							to: 1.0
							duration: 600
						}
					}
				}

				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: qsTr("AI ANALYSIS")
					color: "#aaaacc"
					font.pixelSize: 11
					font.letterSpacing: 2
					font.family: S.Style.fontFamily
				}

				Text {
					visible: !bottomPanel.expanded
					text: root.currentAlert !== "" ? root.currentAlert : qsTr("No anomalies detected")
					color: root.currentAlert !== "" ? "#ff8888" : "#555566"
					font.pixelSize: 11
					font.family: S.Style.fontFamily
					elide: Text.ElideRight
					anchors.verticalCenter: parent.verticalCenter
					width: parent.width - 120
				}

				Text {
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					text: bottomPanel.expanded ? qsTr("▼ collapse") : qsTr("▲ history")
					color: "#555577"
					font.pixelSize: 10
					font.family: S.Style.fontFamily

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: bottomPanel.expanded = !bottomPanel.expanded
					}
				}
			}

			Rectangle {
				visible: bottomPanel.expanded
				width: parent.width
				height: 1
				color: "#2a2a3a"
			}

			Rectangle {
				visible: bottomPanel.expanded
				width: parent.width
				height: currentAlertText.implicitHeight + 12
				radius: 4
				color: root.currentAlert !== "" ? "#33ff4444" : "#1a1a2a"
				border.color: root.currentAlert !== "" ? "#ff4444" : "#2a2a3a"
				border.width: 1

				Text {
					id: currentAlertText
					anchors.fill: parent
					anchors.margins: 6
					text: root.currentAlert !== "" ? root.currentAlert : qsTr("No anomalies detected")
					color: root.currentAlert !== "" ? "#ff8888" : "#555566"
					font.pixelSize: 12
					font.family: S.Style.fontFamily
					wrapMode: Text.WordWrap
				}
			}

			ListView {
				id: historyList
				visible: bottomPanel.expanded
				width: parent.width
				height: bottomPanel.height - 36 - currentAlertText.implicitHeight - 38
				clip: true
				model: root.alertHistory
				spacing: 4
				orientation: ListView.Vertical

				delegate: Rectangle {
					required property var modelData

					width: historyList.width
					height: entryText.implicitHeight + timeText.implicitHeight + 12
					color: "#1a1a2a"
					radius: 3

					Text {
						id: timeText
						anchors.top: parent.top
						anchors.left: parent.left
						anchors.margins: 6
						text: modelData.time
						color: "#444455"
						font.pixelSize: 9
						font.family: S.Style.fontFamily
					}

					Text {
						id: entryText
						anchors.top: timeText.bottom
						anchors.left: parent.left
						anchors.right: parent.right
						anchors.margins: 6
						text: modelData.text
						color: "#aaaacc"
						font.pixelSize: 11
						font.family: S.Style.fontFamily
						wrapMode: Text.WordWrap
					}
				}

				onCountChanged: positionViewAtEnd()
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

		function onAlertChanged(id, alert) {
			if (id !== root.streamId || alert === "")
				return;

			root.currentAlert = alert;

			const now = new Date();
			const time = now.getHours().toString().padStart(2, "0") + ":" + now.getMinutes().toString().padStart(2, "0") + ":" + now.getSeconds().toString().padStart(2, "0");

			let history = root.alertHistory.slice();
			history.unshift({
				time: time,
				text: alert
			});
			if (history.length > 50)
				history = history.slice(0, 50);
			root.alertHistory = history;
		}
	}

	Component.onCompleted: root.claimSink()

	Component.onDestruction: if (root.streamId >= 0)
		CameraManager.setDetectionEnabled(root.streamId, false)
}
