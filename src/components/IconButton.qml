import QtQuick 2.6
import "qrc:/src/theme"

Item {
	id: root
<<<<<<<< HEAD:src/components/IconButton.qml
	width: Style.iconBtnWidth
	height: Style.iconBtnHeight

	property alias iconSource: iconBtnImage.source
========
	width: Style.toolButtonWidth
	height: Style.toolButtonHeight
>>>>>>>> b53e1d1 (feat: pragma singleton added.):src/components/ArmedToolButton.qml

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
