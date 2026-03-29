import QtQuick 2.6
import "qrc:/src/theme"

Item {
	id: root
	width: Style.toolButtonWidth
	height: Style.toolButtonHeight

	signal clicked

	Image {
		anchors.fill: parent
		source: "qrc:/resources/icons/Armed.svg"
		fillMode: Image.PreserveAspectFit
	}

	MouseArea {
		anchors.fill: parent
		onClicked: root.clicked()
	}
}
