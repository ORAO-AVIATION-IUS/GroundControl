import QtQuick

Item {
	id: root
	width: 250
	height: 250

	property double heading: 0
	property double startAngle: 0
	property double degreesPerDegree: 1

	Image {
		id: face
		source: "qrc:/resources/assets/heading_background.svg"
		anchors.fill: parent
		fillMode: Image.PreserveAspectFit
		antialiasing: true
		sourceSize.width: width
		sourceSize.height: height
		z: 1
		rotation: root.startAngle + (root.heading * root.degreesPerDegree)
	}

	Image {
		id: caseOverlay
		source: "qrc:/resources/assets/heading_face.svg"
		anchors.fill: parent
		fillMode: Image.PreserveAspectFit
		antialiasing: true
		sourceSize.width: width
		sourceSize.height: height
		z: 2
	}
}
