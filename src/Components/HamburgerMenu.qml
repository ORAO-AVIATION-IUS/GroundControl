import QtQuick
import QtQuick.Controls

ToolButton {
	id: root

	default property alias items: menu.contentData

	anchors.right: parent.right
	anchors.top: parent.top
	anchors.margins: 4

	width: 32
	height: 32
	text: "☰"
	font.pixelSize: 16

	onClicked: menu.popup()

	Menu {
		id: menu
	}
}
