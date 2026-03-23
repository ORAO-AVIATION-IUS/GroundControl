import QtQuick 2.15

Item {
	id: root
	width: 200
	height: 200
	property real heading: 0

	Rectangle {
		id: circle
		anchors.fill: parent
		radius: width / 2
		color: "transparent"
		border.color: "black"
		border.width: 3
		antialiasing: true

		Image {
			id: compassImg
			source: "qrc:/assets/compass_background.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			width: parent.width
			height: parent.height
		}

		Image {
			id: needleImg
			source: "qrc:/assets/compass_needle.svg"
			anchors.centerIn: parent
			fillMode: Image.PreserveAspectFit
			antialiasing: true
			width: parent.width
			height: parent.height
			rotation: root.heading
		}
	}
}
