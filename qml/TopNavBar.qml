import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "qrc:/resources/components"

Rectangle {
	id: root
	width: parent.width
	height: 50
	color: "#1e272e"

	property string flightStatus: "READY TO FLY"
	property string flightMode: "HOLD"
	property string lastNotification: "System Check OK"
	property int gpsSats: 18
	property int batteryLevel: 85
	property bool isConnected: false
	property bool isConnecting: false

	ButtonGroup {
		id: protocolGroup
	}

	RowLayout {
		anchors.fill: parent
		anchors.leftMargin: 15
		anchors.rightMargin: 15
		spacing: 15

		Row {
			spacing: 10
			Layout.alignment: Qt.AlignVCenter
			Text {
				text: "ORAO"
				color: "white"
				font.bold: true
				font.pixelSize: 18
			}
			Text {
				text: root.flightStatus
				color: "#2ecc71"
				font.pixelSize: 14
				font.bold: true
				anchors.verticalCenter: parent.verticalCenter
			}
		}

		Rectangle {
			width: 70
			height: 26
			color: "#34495e"
			radius: 4
			Layout.alignment: Qt.AlignVCenter
			Text {
				anchors.centerIn: parent
				text: root.flightMode
				color: "#f1c40f"
				font.bold: true
				font.pixelSize: 12
			}
		}

		Button {
			id: notifButton
			implicitWidth: 180
			implicitHeight: 30
			flat: true
			Layout.alignment: Qt.AlignVCenter
			contentItem: Text {
				text: "• " + root.lastNotification
				color: "#bdc3c7"
				font.pixelSize: 12
				elide: Text.ElideRight
				verticalAlignment: Text.AlignVCenter
			}
			onClicked: notifPanel.open()
		}

		Item {
			Layout.fillWidth: true
		}

		Row {
			spacing: 6
			Layout.alignment: Qt.AlignVCenter
			Image {
				source: "qrc:/resources/icons/Gps.svg"
				sourceSize: Qt.size(18, 18)
				visible: status === Image.Ready
			}
			Text {
				text: root.gpsSats
				color: "white"
				font.bold: true
				font.pixelSize: 14
			}
		}

		Text {
			text: "%" + root.batteryLevel
			color: root.batteryLevel < 20 ? "#e74c3c" : "#2ecc71"
			font.bold: true
			font.pixelSize: 14
			Layout.alignment: Qt.AlignVCenter
		}

		RowLayout {
			id: connArea
			spacing: 10
			Layout.alignment: Qt.AlignVCenter

			Text {
				text: root.isConnecting ? "CONNECTING..." : (root.isConnected ? "CONNECTED" : "OFFLINE")
				color: root.isConnected ? "#2ecc71" : (root.isConnecting ? "#f39c12" : "#e74c3c")
				font.bold: true
				font.pixelSize: 13
			}

			Button {
				visible: root.isConnected
				implicitWidth: 24
				implicitHeight: 24
				onClicked: root.isConnected = false
				background: Rectangle {
					color: "transparent"
					border.color: "#e74c3c"
					radius: 12
					Text {
						text: "×"
						anchors.centerIn: parent
						color: "#e74c3c"
						font.bold: true
					}
				}
			}

			Button {
				id: addBtn
				visible: !root.isConnected && !root.isConnecting
				implicitWidth: 28
				implicitHeight: 28
				onClicked: connPopup.open()
				background: Rectangle {
					color: "#3498db"
					radius: 14
					Text {
						text: "+"
						anchors.centerIn: parent
						color: "white"
						font.bold: true
						font.pixelSize: 18
					}
				}
			}

			Button {
				id: configBtn
				implicitWidth: 28
				implicitHeight: 28
				background: Item {
					Image {
						anchors.centerIn: parent
						source: "qrc:/resources/icons/Gears.svg"
						sourceSize: Qt.size(20, 20)
						visible: status === Image.Ready
					}
					Text {
						//icons/settings.svg needed
						visible: parent.children[0].status !== Image.Ready
						text: "⚙"
						color: "white"
						font.pixelSize: 20
						anchors.centerIn: parent
					}
				}
				onClicked: {
					console.log("Settings Panel Requested");
				}
			}
		}
	}

	Popup {
		id: connPopup
		x: connArea.x + addBtn.x - width + addBtn.width
		y: parent.height + 5
		width: 200
		padding: 15
		background: Rectangle {
			color: "#2c3e50"
			radius: 8
			border.color: "#34495e"
			border.width: 2
		}
		contentItem: ColumnLayout {
			spacing: 12
			Text {
				text: "UDP / TCP Connection"
				color: "white"
				font.bold: true
				Layout.alignment: Qt.AlignHCenter
			}
			TextField {
				id: ipInput
				placeholderText: "IP: 127.0.0.1"
				Layout.fillWidth: true
				color: "white"
				background: Rectangle {
					color: "#34495e"
					radius: 4
				}
			}
			TextField {
				id: portInput
				placeholderText: "Port: 14550"
				Layout.fillWidth: true
				color: "white"
				background: Rectangle {
					color: "#34495e"
					radius: 4
				}
			}
			RowLayout {
				Layout.fillWidth: true
				spacing: 5
				Button {
					id: udpBtn
					text: "UDP"
					Layout.fillWidth: true
					checkable: true
					checked: true
					ButtonGroup.group: protocolGroup
					contentItem: Text {
						text: parent.text
						color: parent.checked ? "white" : "#bdc3c7"
						font.bold: parent.checked
						horizontalAlignment: Text.AlignHCenter
					}
					background: Rectangle {
						color: parent.checked ? "#3498db" : "#34495e"
						radius: 4
					}
				}
				Button {
					id: tcpBtn
					text: "TCP"
					Layout.fillWidth: true
					checkable: true
					ButtonGroup.group: protocolGroup
					contentItem: Text {
						text: parent.text
						color: parent.checked ? "white" : "#bdc3c7"
						font.bold: parent.checked
						horizontalAlignment: Text.AlignHCenter
					}
					background: Rectangle {
						color: parent.checked ? "#3498db" : "#34495e"
						radius: 4
					}
				}
			}
			Button {
				text: "CONNECT"
				Layout.fillWidth: true
				onClicked: {
					connPopup.close();
					root.isConnecting = true;
					fakeTimer.start();
				}
				background: Rectangle {
					color: "#27ae60"
					radius: 4
				}
				contentItem: Text {
					text: "CONNECT"
					color: "white"
					font.bold: true
					horizontalAlignment: Text.AlignHCenter
				}
			}
		}
	}

	Popup {
		id: notifPanel
		x: notifButton.x
		y: parent.height + 5
		width: 250
		background: Rectangle {
			color: "#2c3e50"
			radius: 4
			border.color: "#34495e"
		}
		contentItem: Text {
			text: "LOG: " + root.lastNotification + "\n• GPS Fixed\n• Battery Normal"
			color: "white"
			font.pixelSize: 12
			padding: 10
		}
	}

	Timer {
		id: fakeTimer
		interval: 1500
		onTriggered: {
			root.isConnecting = false;
			root.isConnected = true;
			root.lastNotification = "Mavlink Heartbeat Received";
		}
	}
}
