import QtQuick

Item {
	id: root

	property double batteryPercent: 100

	readonly property int _index: {
		var p = batteryPercent;
		if (p >= 80)
			return 0;
		if (p >= 50)
			return 1;
		if (p >= 30)
			return 2;
		if (p >= 15)
			return 3;
		return 4;
	}

	readonly property var _icons: ["battery-100", "battery-070", "battery-040", "battery-020", "battery-000"]

	Image {
		anchors.fill: parent
		source: "image://icon/" + root._icons[root._index]
		fillMode: Image.PreserveAspectFit
	}
}
