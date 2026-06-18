pragma ComponentBehavior: Bound

import Agc.Camera
import Agc.Style as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
	id: root

	property int streamId: -1
	property bool detectionEnabled: false
	property real confidence: 0.3

	modal: false
	focus: true
	padding: 12
	width: 260
	closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

	function refresh() {
		if (root.streamId < 0)
			return;
		root.detectionEnabled = CameraManager.detectionEnabled(root.streamId);
		root.confidence = CameraManager.detectionConfidence(root.streamId);
	}

	onOpened: refresh()

	background: Rectangle {
		color: S.Style.bgPanel
		border.color: S.Style.separator
		border.width: 1
		radius: 6
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: 10

		Text {
			text: qsTr("Human detection")
			color: S.Style.textPrimary
			font.pixelSize: 14
			font.bold: true
			font.family: S.Style.fontFamily
		}

		Text {
			text: qsTr("Confidence: %1%").arg(Math.round(root.confidence * 100))
			color: S.Style.textSecondary
			font.pixelSize: 12
			font.family: S.Style.fontFamily
		}

		Slider {
			Layout.fillWidth: true
			from: 0.1
			to: 0.8
			stepSize: 0.05
			value: root.confidence
			enabled: root.detectionEnabled
			onMoved: root.confidence = value
			onPressedChanged: if (!pressed)
				CameraManager.setDetectionConfidence(root.streamId, value)
		}

		Text {
			Layout.fillWidth: true
			text: qsTr("Only COCO 'person' detections are shown. LLM analysis is disabled.")
			color: S.Style.textMuted
			font.pixelSize: 11
			font.family: S.Style.fontFamily
			wrapMode: Text.WordWrap
		}
	}

	Connections {
		target: CameraManager

		function onDetectionEnabledChanged(id, enabled) {
			if (id === root.streamId)
				root.detectionEnabled = enabled;
		}

		function onDetectionConfidenceChanged(id, confidence) {
			if (id === root.streamId)
				root.confidence = confidence;
		}
	}
}
