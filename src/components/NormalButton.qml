import QtQuick 2.6
import "qrc:/src/theme"

Rectangle {
	id: rootButton

	implicitWidth: Style.normalButtonWidth
	implicitHeight: Style.normalButtonHeight

	property color normalColor: Style.normalButtonColor
	property color hoverColor: Style.normalButtonHoverColor
	property color pressedColor: Style.normalButtonPressedColor

	property alias text: textItem.text
	property alias textColor: textItem.color
	property alias textSize: textItem.font.pixelSize
	property alias font: textItem.font

	signal clicked

	color: mouseArea.pressed ? pressedColor : (mouseArea.containsMouse ? hoverColor : normalColor)
	radius: Style.normalButtonRadius

	Text {
		id: textItem
		anchors.centerIn: parent
		color: Style.normalButtonTextColor
		text: "Button"
		font.pixelSize: Style.normalButtonTextSize
	}

	MouseArea {
		id: mouseArea
		anchors.fill: parent
		hoverEnabled: true
		onClicked: rootButton.clicked()
	}
}
