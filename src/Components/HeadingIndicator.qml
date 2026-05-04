import QtQuick

Item {
	id: root

	property double heading: 0
	property double startAngle: 0
	property double degreesPerDegree: 1

	Item {
		id: face
		anchors.centerIn: parent
		width: Math.min(root.width, root.height)
		height: width

		Image {
			id: faceImg
			source: "qrc:/resources/assets/heading_background.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			sourceSize.width: width * 2
			sourceSize.height: height * 2
			z: 1
			rotation: root.startAngle + (root.heading * root.degreesPerDegree)
		}

		Image {
			id: caseOverlay
			source: "qrc:/resources/assets/heading_face.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			sourceSize.width: width * 2
			sourceSize.height: height * 2
			z: 2
		}
	}
}
