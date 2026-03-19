import QtQuick 2.6

Rectangle {
	id: rootButton

	property int buttonWidth: 120
	property int buttonHeight: 40
	property color buttonColor: "#b2d8ff"
	property color hoverColor: "#80bfff"
	property color pressedColor: '#0e76ff'
	property color textColor: "black"
	property int buttonRadius: 4
	property string buttonTextStr: "Button"
	property int buttonTextSize: 14

	property alias text: textItem.text
	signal clicked

	width: buttonWidth
	height: buttonHeight
	color: mouseArea.pressed ? pressedColor : (mouseArea.containsMouse ? hoverColor : buttonColor)
	radius: buttonRadius

	Text {
		id: textItem
		anchors.centerIn: parent
		color: rootButton.textColor
		text: rootButton.buttonTextStr
		font.pixelSize: rootButton.buttonTextSize
	}

	MouseArea {
		id: mouseArea
		anchors.fill: parent
		hoverEnabled: true
		onClicked: rootButton.clicked()
	}
}
