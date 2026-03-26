import QtQuick 2.6

Item {
	id: root
	width: 24
	height: 24

	signal clicked

	Image {
		anchors.fill: parent
		source: "qrc:/resources/icons/sliders.svg"
		fillMode: Image.PreserveAspectFit
	}

	MouseArea {
		anchors.fill: parent
		onClicked: root.clicked()
	}
}
