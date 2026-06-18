pragma ComponentBehavior: Bound

import Agc.Style as S
import QtQuick

Item {
	id: root

	property rect contentRect
	property var detections: []

	Repeater {
		model: root.detections

		delegate: Item {
			id: detectionDelegate

			required property var modelData

			x: root.contentRect.x + detectionDelegate.modelData.x * root.contentRect.width
			y: root.contentRect.y + detectionDelegate.modelData.y * root.contentRect.height
			width: detectionDelegate.modelData.w * root.contentRect.width
			height: detectionDelegate.modelData.h * root.contentRect.height

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
				width: labelText.implicitWidth + 8
				height: labelText.implicitHeight + 4
				radius: 2

				Text {
					id: labelText
					anchors.centerIn: parent
					text: "%1 %2%".arg(detectionDelegate.modelData.label).arg(Math.round(detectionDelegate.modelData.score * 100))
					color: "#00FF41"
					font.pixelSize: 11
					font.family: S.Style.fontFamily
				}
			}
		}
	}
}
