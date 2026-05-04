import QtQuick

Item {
	id: root

	property double yawspeed: 0
	property double yacc: 0

	property double turnMultiplier: 6.0
	property double slipMultiplier: 15.0

	readonly property double maxBallOffset: face.width * 0.152
	readonly property double ballOffset: Math.max(-maxBallOffset, Math.min(maxBallOffset, yacc * slipMultiplier))

	Item {
		id: face
		anchors.centerIn: parent
		width: Math.min(root.width, root.height)
		height: width

		Image {
			id: bezel
			source: "qrc:/resources/assets/tc_bezel.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			sourceSize.width: width * 2
			sourceSize.height: height * 2
			z: 1
		}

		Image {
			id: scaleBg
			source: "qrc:/resources/assets/tc_scale.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			sourceSize.width: width * 2
			sourceSize.height: height * 2
			z: 2
		}

		Image {
			id: airplane
			source: "qrc:/resources/assets/tc_airplane.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			sourceSize.width: width * 2
			sourceSize.height: height * 2
			z: 3

			rotation: root.yawspeed * root.turnMultiplier

			Behavior on rotation {
				NumberAnimation {
					duration: 150
					easing.type: Easing.OutCubic
				}
			}
		}

		Image {
			id: inclinometer
			source: "qrc:/resources/assets/tc_inclinometer.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			sourceSize.width: width * 2
			sourceSize.height: height * 2
			z: 4
		}

		Image {
			id: ball
			source: "qrc:/resources/assets/tc_ball.svg"
			width: parent.width * 0.072
			height: width
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			z: 5

			y: parent.height / 2 + parent.height * 0.136 - height / 2

			x: {
				var center = parent.width / 2 - width / 2;
				return center + root.ballOffset;
			}

			Behavior on x {
				NumberAnimation {
					duration: 200
					easing.type: Easing.OutCubic
				}
			}
		}

		Image {
			id: glassOverlay
			source: "qrc:/resources/assets/tc_glass.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			sourceSize.width: width * 2
			sourceSize.height: height * 2
			z: 6
		}
	}
}
