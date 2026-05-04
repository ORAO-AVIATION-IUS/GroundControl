import QtQuick

Item {
	id: root
	width: 60
	height: 30

	property int _index: 0
	property var _icons: ["qrc:/resources/icons/BatteryGreen.svg", "qrc:/resources/icons/BatteryYellow.svg", "qrc:/resources/icons/BatteryOrange.svg", "qrc:/resources/icons/BatteryCritical.svg", "qrc:/resources/icons/BatteryEMERGENCY.svg"]

	// TODO

	Image {
		anchors.fill: parent
		source: root._icons[root._index]
		fillMode: Image.PreserveAspectFit
	}
	// Test fonksiyonu
	Timer {
		interval: 1000
		running: true
		repeat: true
		onTriggered: {
			root._index = (root._index + 1) % root._icons.length;
		}
	}
}
