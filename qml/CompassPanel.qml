import QtQuick 2.15

Rectangle {
	id: panelBackground
	color: '#ffffff'
	anchors.fill: parent

	CompassIndicator {
		id: myCompass
		anchors.centerIn: parent
		heading: -150
		width: 400
		height: 400
	}
}
