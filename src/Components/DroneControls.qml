pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
	id: root

	property bool armed: false
	property bool inFlight: false
	property bool connected: false
	property string flightMode: ""
	property string droneId: "--"

	signal armClicked
	signal disarmClicked
	signal takeoffClicked
	signal landClicked
	signal rthClicked

	component ActBtn: Rectangle {
		id: actBtn

		property string label: ""
		property color bgColor: "#f0f0f4"
		property color txtColor: "#3a4a5a"
		property bool highlight: false
		signal tapped

		Layout.fillWidth: true
		Layout.preferredHeight: 26
		radius: 0
		color: !enabled ? Qt.darker(actBtn.bgColor, 0.92) : ma.pressed ? Qt.darker(actBtn.bgColor, 1.12) : ma.containsMouse ? Qt.darker(actBtn.bgColor, 1.06) : actBtn.bgColor
		border.color: actBtn.highlight ? "#4070b0" : Qt.darker(actBtn.bgColor, 1.16)
		border.width: 1
		opacity: enabled ? 1.0 : 0.4

		Text {
			anchors.centerIn: parent
			text: actBtn.label
			color: actBtn.txtColor
			font.pixelSize: 11
			font.bold: true
			font.family: "Segoe UI"
		}

		MouseArea {
			id: ma
			anchors.fill: parent
			hoverEnabled: true
			onClicked: if (actBtn.enabled)
				parent.tapped()
		}
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.top: parent.top
		anchors.margins: 12
		spacing: 0

		Text {
			text: "CONTROLS"
			color: "#a0a8b0"
			font.pixelSize: 9
			font.bold: true
			font.letterSpacing: 1.4
			font.family: "Segoe UI"
			Layout.bottomMargin: 6
		}

		GridLayout {
			Layout.fillWidth: true
			columns: 2
			rowSpacing: 3
			columnSpacing: 3

			ActBtn {
				label: "ARM"
				bgColor: "#edf7f1"
				txtColor: "#1a5830"
				enabled: root.connected && !root.armed
				onTapped: root.armClicked()
			}
			ActBtn {
				label: "DISARM"
				bgColor: "#fdf0ee"
				txtColor: "#6a1e1e"
				enabled: root.connected && root.armed && !root.inFlight
				onTapped: root.disarmClicked()
			}
			ActBtn {
				label: "TAKEOFF"
				bgColor: "#edf2fa"
				txtColor: "#1a3060"
				enabled: root.connected && root.armed && !root.inFlight
				onTapped: root.takeoffClicked()
			}
			ActBtn {
				label: "LAND"
				bgColor: "#faf4ec"
				txtColor: "#4a3010"
				enabled: root.connected && root.inFlight
				onTapped: root.landClicked()
			}
			ActBtn {
				label: "RTH"
				bgColor: "#eef2f8"
				txtColor: "#1a3868"
				enabled: root.connected && root.inFlight
				onTapped: root.rthClicked()
			}
		}

		Rectangle {
			Layout.fillWidth: true
			Layout.preferredHeight: 1
			color: "#e8e8ec"
			Layout.topMargin: 10
			Layout.bottomMargin: 10
		}

		Text {
			text: "FLIGHT MODE"
			color: "#a0a8b0"
			font.pixelSize: 9
			font.bold: true
			font.letterSpacing: 1.4
			font.family: "Segoe UI"
			Layout.bottomMargin: 6
		}

		Rectangle {
			Layout.fillWidth: true
			Layout.preferredHeight: 26
			radius: 0
			color: "#e8f0fa"
			border.color: "#4070b0"
			border.width: 1

			Text {
				anchors.centerIn: parent
				text: root.flightMode || "UNKNOWN"
				color: "#1a4890"
				font.pixelSize: 11
				font.bold: true
				font.family: "Segoe UI"
			}
		}

		Item {
			Layout.fillHeight: true
		}
	}
}
