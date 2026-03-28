import QtQuick 2.6

Rectangle {
	id: rootBox

	property int boxWidth: 200
	property int boxHeight: 150
	property color boxColor: '#002f55'
	property color borderColor: '#cbc1ff'
	property int borderWidth: 2
	property int boxRadius: 8

	property int padding: 10

	default property alias content: innerContainer.data

	width: boxWidth
	height: boxHeight
	color: boxColor
	radius: boxRadius
	border.width: borderWidth
	border.color: borderColor

	Item {
		id: innerContainer
		anchors.fill: parent
		anchors.margins: rootBox.padding
	}
}
