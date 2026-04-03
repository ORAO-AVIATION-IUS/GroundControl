import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
	id: root
	width: parent.width
	height: 50
	color: "#9C9795"

	property int custom_mode: 2
	property int battery_remaining: 50
	property bool isConnected: true
	property bool isConnecting: false
	property int numberofVehicle: 2

	function getModeName(modeId) {
		var modes = {
			0: "STABILIZE",
			2: "HOLD"
		};
		return modes[modeId];
	}

	RowLayout {
		anchors.fill: parent
		anchors.leftMargin: 15
		anchors.rightMargin: 15
		spacing: 15

		Image {
			source: "qrc:/resources/icons/OraoLogo.svg"
			Layout.preferredWidth: 30
			Layout.preferredHeight: 30
		}
		Text {
			text: "Flight Mode: " + getModeName(root.custom_mode)
			color: "#B8FFB8"
			font.pixelSize: 16
		}

		Image {
			source: "qrc:/resources/icons/notification.svg"
			Layout.preferredWidth: 20
			Layout.preferredHeight: 20
		}
		Item {
			Layout.fillWidth: true
		}
		Button {
			id: vehicleButton
			text: "Vehicles: " + root.numberofVehicle
			onClicked: vehicleMenu.open()

			Menu {
				id: vehicleMenu
				y: vehicleButton.height
				width: 200

				MenuItem {
					text: "VTOL-01"
					font.bold: true
				}

				MenuItem {
					text: "Battery: %" + root.battery_remaining
					enabled: false
				}

				MenuItem {

					text: "Status: Disconnected"
					enabled: false
				}

				MenuItem {
					text: "Mode: " + getModeName(root.custom_mode)
					enabled: false
				}

				MenuSeparator {}

				MenuItem {
					text: "VTOL-02"
					font.bold: true
				}

				MenuItem {
					text: "Battery: %" + root.battery_remaining
					enabled: false
				}
				MenuItem {
					text: "Status: " + (root.isConnected ? "Connected" : "Offline")
					enabled: false
				}
				MenuItem {
					text: "Mode: " + getModeName(0)
					enabled: false
				}
			}
		}
		Button {
			text: "Connect"
		}
		Button {

			text: "Config"
			onClicked: {
				font.pixelSize = font.pixelSize + 5;
			}
		}
	}
}
