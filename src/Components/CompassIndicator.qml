import QtQuick

Item {
	id: root
	width: 250
	height: 250
	property real heading: 0

	Image {
		id: compassImg
		source: "qrc:/resources/assets/compass_background.svg"
		anchors.fill: parent
		fillMode: Image.PreserveAspectFit
		antialiasing: true
		width: parent.width
		height: parent.height
		sourceSize.width: width
		sourceSize.height: height
	}

	Image {
		id: needleImg
		source: "qrc:/resources/assets/compass_needle.svg"
		anchors.centerIn: parent
		fillMode: Image.PreserveAspectFit
		antialiasing: true
		width: parent.width
		height: parent.height
		rotation: root.heading
		sourceSize.width: width
		sourceSize.height: height
	}
}
