import QtQuick

Item {
	id: root
	width: 60
	height: 30

	property int _index: 0
	property var _icons: ["battery-100", "battery-070", "battery-040", "battery-020", "battery-000"]

	// TODO

	Image {
		anchors.fill: parent
		source: "image://icon/" + root._icons[root._index]
		fillMode: Image.PreserveAspectFit
	}

	// // Test function
	// Timer {
	// 	interval: 1000
	// 	running: true
	// 	repeat: true
	// 	onTriggered: {
	// 		root._index = (root._index + 1) % root._icons.length;
	// 	}
	// }
}
