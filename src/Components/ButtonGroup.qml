import Agc.Style
import QtQuick

Rectangle {
	id: root

	property string title: ""
	property bool horizontal: false
	default property alias buttons: buttonFlow.data

	implicitWidth: content.implicitWidth + Style.sectionPadding * 2
	implicitHeight: content.implicitHeight + Style.sectionPadding * 2

	color: Style.sectionBgColor
	radius: Style.sectionRadius

	Column {
		id: content
		anchors.centerIn: parent
		spacing: 3

		Text {
			text: root.title
			color: Style.sectionLabelColor
			font.pixelSize: Style.sectionLabelSize
			font.letterSpacing: 1
			visible: root.title !== ""
		}

		Flow {
			id: buttonFlow
			flow: root.horizontal ? Flow.LeftToRight : Flow.TopToBottom
			spacing: root.horizontal ? Style.sectionRowSpacing : Style.sectionSpacing
		}
	}
}
