import Agc.Style
import QtQuick

Item {
	id: root

	signal clicked

	property string droneName: ""
	property bool connected: false
	property string flightMode: ""
	property bool armed: false
	property real altitude: 0.0
	property real batteryPercent: 100.0
	property bool selected: false

	visible: connected
	opacity: visible ? 1.0 : 0.0
	Behavior on opacity {
		NumberAnimation {
			duration: 200
		}
	}

	width: statusRow.implicitWidth + 20
	height: statusRow.implicitHeight + 14

	// selection outline
	Rectangle {
		anchors.fill: parent
		anchors.margins: -2
		radius: Style.sectionRadius + 2
		color: Style.iconBtnCheckedLabelColor
		visible: root.selected
		opacity: visible ? 1.0 : 0.0

		Behavior on opacity {
			NumberAnimation {
				duration: 120
			}
		}
	}

	Rectangle {
		anchors.fill: parent
		color: Style.sectionBgColor
		radius: Style.sectionRadius
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}

	Row {
		id: statusRow
		anchors.centerIn: parent
		spacing: 10

		Rectangle {
			width: 6
			height: 6
			radius: 3
			color: "#2ecc71"
			anchors.verticalCenter: parent.verticalCenter
		}

		Text {
			text: root.droneName
			color: "#e0e0e0"
			font.pixelSize: 8
			font.bold: true
			anchors.verticalCenter: parent.verticalCenter
			visible: root.droneName !== ""
		}

		Text {
			text: root.flightMode
			color: "#cdd6e0"
			font.pixelSize: 8
			font.bold: true
			anchors.verticalCenter: parent.verticalCenter
		}

		Text {
			text: root.armed ? "ARMED" : "DISARMED"
			color: root.armed ? "#e74c3c" : "#6b7a8d"
			font.pixelSize: 7
			font.bold: true
			anchors.verticalCenter: parent.verticalCenter
		}

		Text {
			text: root.altitude.toFixed(0) + " m"
			color: "#8cb4f0"
			font.pixelSize: 8
			anchors.verticalCenter: parent.verticalCenter
		}

		Text {
			text: root.batteryPercent.toFixed(0) + "%"
			color: root.batteryPercent > 30 ? "#2ecc71" : root.batteryPercent > 15 ? "#f39c12" : "#e74c3c"
			font.pixelSize: 8
			font.bold: true
			anchors.verticalCenter: parent.verticalCenter
		}
	}
}
