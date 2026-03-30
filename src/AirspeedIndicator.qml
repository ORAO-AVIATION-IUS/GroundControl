import QtQuick

Item {
	id: root
	width: 250
	height: 250

	property double airspeedMs: 0
	property double startAngle: 0
	property double degreesPerKnot: 1.5
	readonly property double airspeedKnots: airspeedMs * 1.94384

	Rectangle {
		id: circle
		anchors.fill: parent
		radius: width / 2
		color: "transparent"
		border.color: "black"
		border.width: 3
		antialiasing: true
		z: 3
	}

	Image {
		id: background
		source: "qrc:/assets/airspeed_background.svg"
		anchors.fill: parent
		fillMode: Image.PreserveAspectFit
		antialiasing: true
		sourceSize.width: width
		sourceSize.height: height
		z: 1
	}

	Image {
		id: pointer
		source: "qrc:/assets/airspeed_pointer.svg"
		anchors.fill: parent
		fillMode: Image.PreserveAspectFit
		antialiasing: true
		sourceSize.width: width
		sourceSize.height: height
		z: 2
		rotation: root.startAngle + (root.airspeedKnots * root.degreesPerKnot)
	}
}
