import QtQuick

Item {
	id: root

	property double airspeedMs: 0
	readonly property double airspeedKnots: Math.max(20, Math.min(200, airspeedMs * 1.94384))
	readonly property double needleAngle: (airspeedKnots - 20) / 180 * 300 - 150

	Item {
		id: face
		anchors.centerIn: parent
		width: Math.min(root.width, root.height)
		height: width

		Image {
			id: background
			source: "qrc:/resources/assets/airspeed_background.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			sourceSize.width: width
			sourceSize.height: height
			z: 1
		}

		Image {
			id: pointer
			source: "qrc:/resources/assets/airspeed_pointer.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			sourceSize.width: width
			sourceSize.height: height
			z: 2

			rotation: root.needleAngle

			Behavior on rotation {
				NumberAnimation {
					duration: 150
					easing.type: Easing.OutCubic
				}
			}
		}
	}
}
