import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: root
	uniqueName: "rightPanel"
	title: qsTr("Flight Controls")

	Rectangle {
		anchors.fill: parent
		color: "#1e1e2e"

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 16
			spacing: 12

			// --- Connection Status ---
			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: statusRow.height + 20
				color: droneManager.connected ? "#1b4332" : "#3c1361"
				radius: 8

				RowLayout {
					id: statusRow
					anchors.centerIn: parent
					spacing: 8

					Rectangle {
						Layout.preferredWidth: 10
						Layout.preferredHeight: 10
						radius: 5
						color: droneManager.connected ? "#2ecc71" : "#e74c3c"
					}

					Label {
						text: droneManager.connectionStatus
						color: "#ffffff"
						font.pixelSize: 14
						font.bold: true
					}
				}
			}

			// --- Telemetry Readouts ---
			GridLayout {
				Layout.fillWidth: true
				columns: 2
				rowSpacing: 6
				columnSpacing: 10
				enabled: droneManager.connected
				opacity: droneManager.connected ? 1.0 : 0.4

				Label {
					text: qsTr("Mode")
					color: "#aaa"
					font.pixelSize: 12
				}
				Label {
					text: droneManager.flightMode || "—"
					color: "#fff"
					font.pixelSize: 13
					font.bold: true
					Layout.fillWidth: true
				}

				Label {
					text: qsTr("Armed")
					color: "#aaa"
					font.pixelSize: 12
				}
				Label {
					text: droneManager.armed ? qsTr("YES") : qsTr("NO")
					color: droneManager.armed ? "#e74c3c" : "#2ecc71"
					font.pixelSize: 13
					font.bold: true
				}

				Label {
					text: qsTr("Altitude")
					color: "#aaa"
					font.pixelSize: 12
				}
				Label {
					text: droneManager.altitude.toFixed(1) + " m"
					color: "#fff"
					font.pixelSize: 13
					font.bold: true
				}

				Label {
					text: qsTr("Ground Speed")
					color: "#aaa"
					font.pixelSize: 12
				}
				Label {
					text: (droneManager.groundSpeed * 3.6).toFixed(1) + " km/h"
					color: "#fff"
					font.pixelSize: 13
					font.bold: true
				}

				Label {
					text: qsTr("V/S")
					color: "#aaa"
					font.pixelSize: 12
				}
				Label {
					text: droneManager.verticalSpeed.toFixed(1) + " m/s"
					color: droneManager.verticalSpeed > 0.5 ? "#2ecc71" : droneManager.verticalSpeed < -0.5 ? "#e74c3c" : "#fff"
					font.pixelSize: 13
					font.bold: true
				}

				Label {
					text: qsTr("Battery")
					color: "#aaa"
					font.pixelSize: 12
				}
				Label {
					text: droneManager.batteryPercent.toFixed(0) + "% (" + droneManager.batteryVoltage.toFixed(1) + "V)"
					color: droneManager.batteryPercent > 30 ? "#2ecc71" : droneManager.batteryPercent > 15 ? "#f39c12" : "#e74c3c"
					font.pixelSize: 13
					font.bold: true
				}
			}

			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: 1
				color: "#444"
			}

			// --- Action Buttons ---
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 8
				enabled: droneManager.connected

				Button {
					id: armBtn
					Layout.fillWidth: true
					Layout.preferredHeight: 44
					text: droneManager.armed ? qsTr("DISARM") : qsTr("ARM")
					enabled: droneManager.connected

					background: Rectangle {
						color: armBtn.enabled ? (droneManager.armed ? "#c0392b" : "#27ae60") : "#555"
						radius: 6
					}

					contentItem: Label {
						text: armBtn.text
						color: "#fff"
						font.pixelSize: 15
						font.bold: true
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
					}

					onClicked: droneManager.armed ? droneManager.disarm() : droneManager.arm()
				}

				Button {
					id: takeoffBtn
					Layout.fillWidth: true
					Layout.preferredHeight: 44
					text: qsTr("TAKEOFF")
					enabled: droneManager.connected && droneManager.armed && !droneManager.inAir

					background: Rectangle {
						color: takeoffBtn.enabled ? "#2980b9" : "#555"
						radius: 6
					}

					contentItem: Label {
						text: takeoffBtn.text
						color: "#fff"
						font.pixelSize: 15
						font.bold: true
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
					}

					onClicked: droneManager.takeoff()
				}

				Button {
					id: landBtn
					Layout.fillWidth: true
					Layout.preferredHeight: 44
					text: qsTr("LAND")
					enabled: droneManager.connected && droneManager.inAir

					background: Rectangle {
						color: landBtn.enabled ? "#e67e22" : "#555"
						radius: 6
					}

					contentItem: Label {
						text: landBtn.text
						color: "#fff"
						font.pixelSize: 15
						font.bold: true
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
					}

					onClicked: droneManager.land()
				}

				Button {
					id: rtlBtn
					Layout.fillWidth: true
					Layout.preferredHeight: 44
					text: qsTr("RETURN TO LAUNCH")
					enabled: droneManager.connected && droneManager.inAir

					background: Rectangle {
						color: rtlBtn.enabled ? "#8e44ad" : "#555"
						radius: 6
					}

					contentItem: Label {
						text: rtlBtn.text
						color: "#fff"
						font.pixelSize: 15
						font.bold: true
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
					}

					onClicked: droneManager.returnToLaunch()
				}
			}

			Item {
				Layout.fillHeight: true
			}
		}
	}
}
