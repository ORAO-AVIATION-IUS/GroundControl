pragma ComponentBehavior: Bound

import Agc.Components
import Agc.Mavlink
import QtQuick
import QtQuick.Layouts
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: root

	// The drone this panel is bound to. null = no drone selected.
	property DroneManager drone: null

	uniqueName: "dronePanel"
	title: drone ? drone.droneName : qsTr("Drone Control")

	// KDDW expects exactly one child. Use an Item as the single container.
	Item {
		anchors.fill: parent

		Text {
			anchors.centerIn: parent
			text: qsTr("No drone selected")
			color: "#999"
			font.pixelSize: 16
			visible: !root.drone
		}

		Loader {
			id: droneLoader

			anchors.fill: parent
			active: root.drone !== null
			sourceComponent: droneContent

			property DroneManager d: root.drone
		}
	}

	Component {
		id: droneContent

		Item {
			id: droneItem

			// Bound from the Loader's custom property.
			property DroneManager d: droneLoader.d

			ListModel {
				id: logModel
			}

			Connections {
				target: droneItem.d
				function onLogMessage(source, message, level) {
					const dt = new Date();
					const ts = String(dt.getHours()).padStart(2, '0') + ":" + String(dt.getMinutes()).padStart(2, '0') + ":" + String(dt.getSeconds()).padStart(2, '0');
					logModel.insert(0, {
						"ts": ts,
						"src": source,
						"msg": message,
						"level": level
					});
					if (logModel.count > 200)
						logModel.remove(200, logModel.count - 200);
				}
			}

			Rectangle {
				anchors.fill: parent
				color: "#ffffff"

				ColumnLayout {
					anchors.fill: parent
					spacing: 0

					SwarmHeader {
						Layout.fillWidth: true
						droneId: droneItem.d.droneName
						activeMode: droneItem.d.activeMode
						readyToFly: droneItem.d.readyToFly
						armed: droneItem.d.armed
						battery: droneItem.d.battery
						voltage: droneItem.d.voltage
						onModeClicked: droneItem.d.cycleMode()
					}

					Rectangle {
						Layout.fillWidth: true
						Layout.fillHeight: true
						color: "#ffffff"
						clip: true

						RowLayout {
							anchors.fill: parent
							spacing: 0

							TelemetrySidebar {
								Layout.preferredWidth: 150
								Layout.fillHeight: true
								roll: droneItem.d.roll
								pitch: droneItem.d.pitch
								yaw: droneItem.d.yaw
								altRel: droneItem.d.altitude
								climbRate: droneItem.d.climbRate
								groundspeed: droneItem.d.groundspeed
								heading: droneItem.d.heading
								battery: droneItem.d.battery
								voltage: droneItem.d.voltage
								ping: droneItem.d.ping
							}

							Rectangle {
								Layout.preferredWidth: 1
								Layout.fillHeight: true
								color: "#e8e8ec"
							}

							InstrumentGrid {
								Layout.fillWidth: true
								Layout.fillHeight: true
								pitch: droneItem.d.pitch
								roll: droneItem.d.roll
								heading: droneItem.d.heading
							}

							Rectangle {
								Layout.preferredWidth: 1
								Layout.fillHeight: true
								color: "#e8e8ec"
							}

							DroneControls {
								Layout.preferredWidth: 230
								Layout.fillHeight: true
								armed: droneItem.d.armed
								activeMode: droneItem.d.activeMode
								droneId: droneItem.d.droneName
								onArmClicked: droneItem.d.arm()
								onDisarmClicked: droneItem.d.disarm()
								onTakeoffClicked: droneItem.d.takeoff()
								onLandClicked: droneItem.d.land()
								onResetClicked: droneItem.d.rth()
								onConfigClicked: droneItem.d.log(droneItem.d.droneName, "CONFIG command sent", "info")
								onModeSelected: function (mode) {
									droneItem.d.setMode(mode);
								}
							}

							Rectangle {
								Layout.preferredWidth: 1
								Layout.fillHeight: true
								color: "#e8e8ec"
							}

							StatusLog {
								Layout.fillWidth: true
								Layout.fillHeight: true
								model: logModel
								onClearClicked: logModel.clear()
							}

							AltitudeTape {
								Layout.preferredWidth: 110
								Layout.fillHeight: true
								altitude: droneItem.d.altitude
							}
						}
					}
				}
			}
		}
	}
}
