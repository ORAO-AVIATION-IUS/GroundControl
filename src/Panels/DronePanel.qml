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

	function syncDroneContent() {
		droneLoader.sourceComponent = null;
		droneLoader.d = root.drone;
		if (droneLoader.d)
			droneLoader.sourceComponent = droneContent;
	}

	onDroneChanged: syncDroneContent()
	Component.onCompleted: syncDroneContent()

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

			property DroneManager d: null
		}
	}

	Component {
		id: droneContent

		Item {
			id: droneItem

			property DroneManager d: droneLoader.d
			readonly property bool hasDrone: d !== null

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
						droneId: droneItem.hasDrone ? droneItem.d.droneName : ""
						flightMode: droneItem.hasDrone ? droneItem.d.flightMode : ""
						readyToFly: droneItem.hasDrone ? droneItem.d.readyToFly : false
						armed: droneItem.hasDrone ? droneItem.d.armed : false
						inFlight: droneItem.hasDrone ? droneItem.d.inFlight : false
						battery: droneItem.hasDrone ? droneItem.d.battery : 0
						voltage: droneItem.hasDrone ? droneItem.d.voltage : 0
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
								roll: droneItem.hasDrone ? droneItem.d.roll : 0
								pitch: droneItem.hasDrone ? droneItem.d.pitch : 0
								yaw: droneItem.hasDrone ? droneItem.d.yaw : 0
								altRel: droneItem.hasDrone ? droneItem.d.altitude : 0
								climbRate: droneItem.hasDrone ? droneItem.d.climbRate : 0
								groundspeed: droneItem.hasDrone ? droneItem.d.groundspeed : 0
								heading: droneItem.hasDrone ? droneItem.d.heading : 0
								battery: droneItem.hasDrone ? droneItem.d.battery : 0
								voltage: droneItem.hasDrone ? droneItem.d.voltage : 0
								ping: droneItem.hasDrone ? droneItem.d.ping : 0
							}

							Rectangle {
								Layout.preferredWidth: 1
								Layout.fillHeight: true
								color: "#e8e8ec"
							}

							InstrumentGrid {
								Layout.fillWidth: true
								Layout.fillHeight: true
								pitch: droneItem.hasDrone ? droneItem.d.pitch : 0
								roll: droneItem.hasDrone ? droneItem.d.roll : 0
								heading: droneItem.hasDrone ? droneItem.d.heading : 0
							}

							Rectangle {
								Layout.preferredWidth: 1
								Layout.fillHeight: true
								color: "#e8e8ec"
							}

							DroneControls {
								Layout.preferredWidth: 230
								Layout.fillHeight: true
								armed: droneItem.hasDrone ? droneItem.d.armed : false
								inFlight: droneItem.hasDrone ? droneItem.d.inFlight : false
								connected: droneItem.hasDrone ? droneItem.d.connected : false
								flightMode: droneItem.hasDrone ? droneItem.d.flightMode : ""
								droneId: droneItem.hasDrone ? droneItem.d.droneName : ""
								onArmClicked: if (droneItem.hasDrone)
									droneItem.d.arm()
								onDisarmClicked: if (droneItem.hasDrone)
									droneItem.d.disarm()
								onTakeoffClicked: if (droneItem.hasDrone)
									droneItem.d.takeoff()
								onLandClicked: if (droneItem.hasDrone)
									droneItem.d.land()
								onRthClicked: if (droneItem.hasDrone)
									droneItem.d.rth()
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
								altitude: droneItem.hasDrone ? droneItem.d.altitude : 0
							}
						}
					}
				}
			}
		}
	}
}
