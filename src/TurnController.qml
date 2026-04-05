import QtQuick

Item {
	id: root
	width: 250
	height: 250

	property double yawspeed: 0
	property double yacc: 0

	property double turnMultiplier: 6.0
	property double slipMultiplier: 15.0
	property double maxBallOffset: 38

	readonly property double ballOffset: Math.max(-maxBallOffset, Math.min(maxBallOffset, yacc * slipMultiplier))

	Image {
		id: bezel
		source: "qrc:/resources/assets/tc_bezel.svg"
		anchors.fill: parent
		fillMode: Image.PreserveAspectFit
		antialiasing: true
		sourceSize.width: width
		sourceSize.height: height
		z: 1
	}

	Image {
		id: scaleBg
		source: "qrc:/resources/assets/tc_scale.svg"
		anchors.fill: parent
		fillMode: Image.PreserveAspectFit
		antialiasing: true
		sourceSize.width: width
		sourceSize.height: height
		z: 2
	}

	Image {
		id: airplane
		source: "qrc:/resources/assets/tc_airplane.svg"
		anchors.fill: parent
		fillMode: Image.PreserveAspectFit
		antialiasing: true
		sourceSize.width: width
		sourceSize.height: height
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
		sourceSize.width: width
		sourceSize.height: height
		z: 4
	}

	Image {
		id: ball
		source: "qrc:/resources/assets/tc_ball.svg"
		width: 18
		height: 18
		fillMode: Image.PreserveAspectFit
		antialiasing: true
		z: 5

		y: parent.height / 2 + 34 - height / 2

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
		sourceSize.width: width
		sourceSize.height: height
		z: 6
	}
}
