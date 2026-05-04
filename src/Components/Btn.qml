import QtQuick
import Agc.Style

Rectangle {
	id: rootButton

	implicitWidth: Style.btnWidth
	implicitHeight: Style.btnHeight

	property color normalColor: Style.btnColor
	property color hoverColor: Style.btnHoverColor
	property color pressedColor: Style.btnPressedColor

	property alias text: textItem.text
	property alias textColor: textItem.color
	property alias textSize: textItem.font.pixelSize
	property alias font: textItem.font

	signal clicked

	color: mouseArea.pressed ? pressedColor : (mouseArea.containsMouse ? hoverColor : normalColor)
	radius: Style.btnRadius

	Text {
		id: textItem
		anchors.centerIn: parent
		color: Style.btnTextColor
		text: "Button"
		font.pixelSize: Style.btnTextSize
	}

	MouseArea {
		id: mouseArea
		anchors.fill: parent
		hoverEnabled: true
		onClicked: rootButton.clicked()
	}
}
