pragma ComponentBehavior: Bound

import Agc.Style as S
import QtQuick

Item {
	id: root

	property rect contentRect
	property var detections: []
	readonly property color boxColor: "#ff3b30"

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
				border.color: root.boxColor
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
					text: qsTr("person %1%").arg(Math.round(detectionDelegate.modelData.score * 100))
					color: root.boxColor
					font.pixelSize: 11
					font.family: S.Style.fontFamily
				}
			}
		}
	}
}
