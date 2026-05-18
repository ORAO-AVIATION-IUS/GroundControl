pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
	id: root

	property bool armed: false
	property string activeMode: ""
	property string droneId: "--"

	signal armClicked
	signal disarmClicked
	signal takeoffClicked
	signal landClicked
	signal resetClicked
	signal configClicked
	signal modeSelected(string mode)

	component ActBtn: Rectangle {
		id: actBtn

		property string label: ""
		property color bgColor: "#f0f0f4"
		property color txtColor: "#3a4a5a"
		signal tapped

		Layout.fillWidth: true
		Layout.preferredHeight: 26
		radius: 0
		color: ma.pressed ? Qt.darker(actBtn.bgColor, 1.12) : ma.containsMouse ? Qt.darker(actBtn.bgColor, 1.06) : actBtn.bgColor
		border.color: Qt.darker(actBtn.bgColor, 1.16)
		border.width: 1

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
			onClicked: parent.tapped()
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
				enabled: !root.armed
				opacity: root.armed ? 0.38 : 1.0
				onTapped: root.armClicked()
			}
			ActBtn {
				label: "DISARM"
				bgColor: "#fdf0ee"
				txtColor: "#6a1e1e"
				enabled: root.armed
				opacity: root.armed ? 1.0 : 0.38
				onTapped: root.disarmClicked()
			}
			ActBtn {
				label: "TAKEOFF"
				bgColor: "#edf2fa"
				txtColor: "#1a3060"
				onTapped: root.takeoffClicked()
			}
			ActBtn {
				label: "LAND"
				bgColor: "#faf4ec"
				txtColor: "#4a3010"
				onTapped: root.landClicked()
			}
			ActBtn {
				label: "RESET"
				bgColor: "#f0f0f4"
				txtColor: "#3a4a5a"
				onTapped: root.resetClicked()
			}
			ActBtn {
				label: "CONFIG"
				bgColor: "#f0f0f4"
				txtColor: "#3a4a5a"
				onTapped: root.configClicked()
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

		GridLayout {
			Layout.fillWidth: true
			columns: 2
			rowSpacing: 3
			columnSpacing: 3

			Repeater {
				model: ["STBY", "GUIDED", "AUTO", "RTL", "LOITER", "LAND"]

				delegate: Rectangle {
					id: modeDelegate

					required property string modelData

					Layout.fillWidth: true
					Layout.preferredHeight: 26
					radius: 0
					color: root.activeMode === modeDelegate.modelData ? "#e8f0fa" : modeArea.containsMouse ? "#f4f6fa" : "#f8f8fa"
					border.color: root.activeMode === modeDelegate.modelData ? "#4070b0" : "#dcdce4"
					border.width: 1

					Text {
						anchors.centerIn: parent
						text: modeDelegate.modelData
						color: root.activeMode === modeDelegate.modelData ? "#1a4890" : "#4a5060"
						font.pixelSize: 11
						font.bold: root.activeMode === modeDelegate.modelData
						font.family: "Segoe UI"
					}

					MouseArea {
						id: modeArea
						anchors.fill: parent
						hoverEnabled: true
						onClicked: root.modeSelected(modeDelegate.modelData)
					}
				}
			}
		}

		Item {
			Layout.fillHeight: true
		}
	}
}
