import Agc.Style
import QtQuick

Rectangle {
	id: rootBox

	property int boxWidth: Style.boxWidth
	property int boxHeight: Style.boxHeight
	property color boxColor: Style.boxColor
	property color borderColor: Style.boxBorderColor
	property int borderWidth: Style.boxBorderWidth
	property int boxRadius: Style.boxRadius
	property int padding: Style.boxPadding

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
