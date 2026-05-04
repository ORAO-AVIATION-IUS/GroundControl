import QtQuick

Item {
	id: root
	property real heading: 0

	Item {
		id: face
		anchors.centerIn: parent
		width: Math.min(root.width, root.height)
		height: width

		Image {
			id: compassImg
			source: "qrc:/resources/assets/compass_background.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			sourceSize.width: width * 2
			sourceSize.height: height * 2
		}

		Image {
			id: needleImg
			source: "qrc:/resources/assets/compass_needle.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			rotation: root.heading
			sourceSize.width: width * 2
			sourceSize.height: height * 2
		}
	}
}
