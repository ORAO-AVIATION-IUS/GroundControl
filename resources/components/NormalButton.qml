import QtQuick 2.6

Rectangle {
	id: rootButton

	implicitWidth: 64
	implicitHeight: 24

	property color normalColor: "#b2d8ff"
	property color hoverColor: "#80bfff"
	property color pressedColor: "#0e76ff"

	property alias text: textItem.text
	property alias textColor: textItem.color
	property alias textSize: textItem.font.pixelSize
	property alias font: textItem.font

	signal clicked

	color: mouseArea.pressed ? pressedColor : (mouseArea.containsMouse ? hoverColor : normalColor)
	radius: 4

	Text {
		id: textItem
		anchors.centerIn: parent
		color: "black"
		text: "Button"
		font.pixelSize: 10
	}

	MouseArea {
		id: mouseArea
		anchors.fill: parent
		hoverEnabled: true
		onClicked: rootButton.clicked()
	}
}
