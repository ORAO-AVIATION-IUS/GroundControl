import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
	id: navbar
	width: parent.width
	height: 45
	color: "#1a1a1a" //koyu gri
	opacity: 0.9

	Rectangle {
		width: parent.width
		height: 1
		color: "#333333"
		anchors.bottom: parent.bottom
	}

	RowLayout {
		anchors.fill: parent
		anchors.leftMargin: 20
		anchors.rightMargin: 20
		spacing: 30

		//logo and name
		Text {
			text: "ORAO Ground Control"
			color: "#00bfff" //skyblue
			font.pixelSize: 18
			font.bold: true
			Layout.alignment: Qt.AlignVCenter
		}

		// connection informations
		Row {
			spacing: 8
			Layout.alignment: Qt.AlignVCenter

			Rectangle {
				width: 12; height: 12
				radius: 6
				color: mavManager.isConnected ? "#2ecc71" : "#e74c3c"
				anchors.verticalCenter: parent.verticalCenter

				SequentialAnimation on opacity {
					running: mavManager.isConnected
					loops: Animation.Infinite
					NumberAnimation { from: 1.0; to: 0.5; duration: 800 }
					NumberAnimation { from: 0.5; to: 1.0; duration: 800 }
				}
			}

			Text {
				text: mavManager.isConnected ? "CONNECTED" : "DISCONNECTED"
				color: "white"
				font.pixelSize: 12
				font.bold: true
			}
		}

		Rectangle { width: 1; height: 20; color: "#444"; Layout.alignment: Qt.AlignVCenter }

		//Telemetri datas by one by

		// PITCH
		Column {
			Text { text: "PITCH"; color: "#aaa"; font.pixelSize: 10; font.bold: true }
			Text {
				text: mavManager.pitch.toFixed(1) + "°"
				color: "white"; font.pixelSize: 14; font.family: "Monospace"
			}
		}

		Column {
			Text { text: "ROLL"; color: "#aaa"; font.pixelSize: 10; font.bold: true }
			Text {
				text: mavManager.roll.toFixed(1) + "°"
				color: "white"; font.pixelSize: 14; font.family: "Monospace"
			}
		}

		// YAW / HEADING
		Column {
			Text { text: "HEADING"; color: "#aaa"; font.pixelSize: 10; font.bold: true }
			Text {
				text: mavManager.yaw.toFixed(0) + "°"
				color: "#f1c40f"; font.pixelSize: 14; font.family: "Monospace"
			}
		}

		// Boşluk bırakarak sağ tarafa itiyoruz
		Item { Layout.fillWidth: true }

		//battery
		Row {
			spacing: 15
			Layout.alignment: Qt.AlignVCenter

			//batarya
			Text {
				text: "🔋 " + mavManager.batteryRemaining + "%"
				color: mavManager.batteryRemaining < 20 ? "#e74c3c" : "#2ecc71" // %20 altı kırmızı
				font.pixelSize: 14
			}

			// Uçuş Modu Kutusu
			Rectangle {
				color: mavManager.isConnected ? "#2980b9" : "#7f8c8d" // Bağlı değilse gri yap
				width: 100; height: 24
				radius: 4

				Text {
					anchors.centerIn: parent
					text: mavManager.flightMode
					color: "white"
					font.bold: true
					font.pixelSize: 11
				}
			}
		}
	}
}
