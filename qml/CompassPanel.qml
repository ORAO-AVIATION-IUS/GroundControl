import QtQuick 2.15

Rectangle {
	id: panelBackground
	color: '#ffffff'
	anchors.fill: parent

	CompassIndicator {
		id: myCompass
		anchors.centerIn: parent

		heading: (typeof mavManager !== "undefined") ? mavManager.yaw : 0
	}
}
