import QtQuick 2.6

Rectangle {
	id: root
	property alias text: buttonText.text
	signal clicked

	width: 120
	height: 40
	color: '#b2d8ff'

	Text {
		id: buttonText
		anchors.centerIn: parent
		color: "Black"
		text: "Button"
	}

	MouseArea {
		anchors.fill: parent
		onClicked: root.clicked()
	}
}
