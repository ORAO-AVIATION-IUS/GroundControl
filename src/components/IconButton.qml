import QtQuick 2.6
import "qrc:/src/theme"

Item {
	id: root
	width: Style.iconBtnWidth
	height: Style.iconBtnHeight

	property alias iconSource: iconBtnImage.source

	signal clicked

	Image {
		id: iconBtnImage
		anchors.fill: parent
		fillMode: Image.PreserveAspectFit
	}

	MouseArea {
		anchors.fill: parent
		onClicked: root.clicked()
	}
}
