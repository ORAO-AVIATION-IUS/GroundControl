import QtQuick
import QtQuick.Layouts

Item {
	id: root
	height: 44

	property string droneId: "--"
	property string flightMode: ""
	property bool readyToFly: false
	property bool armed: false
	property bool inFlight: false
	property int battery: 0
	property real voltage: 0.0

	RowLayout {
		anchors.fill: parent
		anchors.leftMargin: 14
		anchors.rightMargin: 14
		spacing: 0

		Text {
			text: root.droneId
			font.pixelSize: 15
			font.bold: true
			font.family: "Segoe UI"
			color: "#1a1a2e"
			Layout.alignment: Qt.AlignVCenter
		}

		Rectangle {
			Layout.preferredWidth: 1
			Layout.preferredHeight: 20
			color: "#e4e4e8"
			Layout.alignment: Qt.AlignVCenter
			Layout.leftMargin: 12
			Layout.rightMargin: 12
		}

		Text {
			text: root.readyToFly ? "Ready To Fly" : "Not Ready"
			font.pixelSize: 15
			font.bold: true
			font.family: "Segoe UI"
			color: root.readyToFly ? "#1e7a40" : "#8a2010"
			Layout.alignment: Qt.AlignVCenter
		}

		Rectangle {
			Layout.preferredWidth: 1
			Layout.preferredHeight: 20
			color: "#e4e4e8"
			Layout.alignment: Qt.AlignVCenter
			Layout.leftMargin: 12
			Layout.rightMargin: 12
		}

		Text {
			text: root.flightMode || "UNKNOWN"
			font.pixelSize: 15
			font.bold: true
			font.family: "Segoe UI"
			color: "#344878"
			Layout.alignment: Qt.AlignVCenter
		}

		Rectangle {
			Layout.preferredWidth: 1
			Layout.preferredHeight: 20
			color: "#e4e4e8"
			Layout.alignment: Qt.AlignVCenter
			Layout.leftMargin: 12
			Layout.rightMargin: 12
		}

		Text {
			text: root.inFlight ? "IN AIR" : root.armed ? "ARMED" : "DISARMED"
			font.pixelSize: 15
			font.bold: true
			font.family: "Segoe UI"
			color: root.inFlight ? "#1a50a0" : root.armed ? "#1e7a40" : "#606878"
			Layout.alignment: Qt.AlignVCenter
		}

		Item {
			Layout.fillWidth: true
		}

		Rectangle {
			Layout.alignment: Qt.AlignVCenter
			Layout.rightMargin: 6
			Layout.preferredWidth: 76
			Layout.preferredHeight: 30
			radius: 0
			color: "#f6f8fa"
			border.color: "#e0e4ea"
			border.width: 1

			Rectangle {
				width: 3
				height: parent.height
				radius: 0
				color: root.battery > 50 ? "#1e7a40" : root.battery > 20 ? "#c08000" : "#c02010"
			}

			Column {
				anchors.left: parent.left
				anchors.leftMargin: 9
				anchors.verticalCenter: parent.verticalCenter
				spacing: 1

				Text {
					text: "BATTERY"
					font.pixelSize: 8
					font.family: "Segoe UI"
					color: "#9090a0"
				}
				Text {
					text: root.battery + "%  " + root.voltage.toFixed(1) + " V"
					font.pixelSize: 9
					font.bold: true
					font.family: "Segoe UI"
					color: "#1a1a2e"
				}
			}
		}

		Rectangle {
			Layout.alignment: Qt.AlignVCenter
			Layout.rightMargin: 12
			Layout.preferredWidth: 76
			Layout.preferredHeight: 30
			radius: 0
			color: root.armed ? "#edf7f1" : "#f6f6f8"
			border.color: root.armed ? "#8ecaaa" : "#dcdce4"
			border.width: 1

			Rectangle {
				width: 3
				height: parent.height
				radius: 0
				color: root.armed ? "#1e7a40" : "#c0c4cc"
			}

			Column {
				anchors.left: parent.left
				anchors.leftMargin: 9
				anchors.verticalCenter: parent.verticalCenter
				spacing: 1

				Text {
					text: "STATUS"
					font.pixelSize: 8
					font.family: "Segoe UI"
					color: "#9090a0"
				}
				Text {
					text: root.armed ? "ARMED" : "DISARMED"
					font.pixelSize: 9
					font.bold: true
					font.family: "Segoe UI"
					color: root.armed ? "#1a6030" : "#606878"
				}
			}
		}
	}

	Rectangle {
		anchors.bottom: parent.bottom
		width: parent.width
		height: 1
		color: "#e4e4e8"
	}
}
