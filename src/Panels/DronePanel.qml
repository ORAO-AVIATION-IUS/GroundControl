pragma ComponentBehavior: Bound

import Agc.Components
import Agc.Mavlink
import Agc.Style as S
import QtQuick
import QtQuick.Layouts
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: root

	// The drone this panel is bound to. null = no drone selected.
	property DroneManager drone: null

	// Wiring for the Log / Cameras tab area (supplied by Main.qml).
	property var cameraModel: null   // full camera ListModel (rows carry droneUid)
	property var cameraDocks: null   // Repeater of standalone CameraPanel docks
	property var logDocks: null      // Repeater of per-drone Log docks
	// Only the primary panel for a drone renders inline camera streams.
	property bool panelIsPrimary: true

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

		Rectangle {
			anchors.fill: parent
			color: S.Style.bgPanel
		}

		Text {
			anchors.centerIn: parent
			text: qsTr("No drone selected")
			color: S.Style.textSecondary
			font.pixelSize: 16
			font.family: S.Style.fontFamily
			visible: !droneLoader.d
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

			// This drone's index in the swarm, used to pick its plan color so
			// the panel matches the map overlay.
			readonly property int droneIndex: {
				if (!droneItem.d)
					return 0;
				for (let i = 0; i < SwarmManager.droneCount; ++i) {
					if (SwarmManager.droneAt(i) === droneItem.d)
						return i;
				}
				return 0;
			}

			// This drone's per-drone Log dock, resolved from root.logDocks.
			// Re-evaluates when docks appear or the drone changes.
			readonly property var myLogDock: {
				const dks = root.logDocks;
				if (!dks || !droneItem.d)
					return null;
				const n = dks.count;
				for (let i = 0; i < n; ++i) {
					const dk = dks.itemAt(i);
					if (dk && dk.droneUid === droneItem.d.droneUid)
						return dk;
				}
				return null;
			}

			onDChanged: if (!d)
				droneLoader.sourceComponent = null

			Rectangle {
				anchors.fill: parent
				color: S.Style.bgPanel

				ColumnLayout {
					anchors.fill: parent
					spacing: 0

					SwarmHeader {
						Layout.fillWidth: true
						droneId: droneItem.d.droneName
						flightMode: droneItem.d.flightMode
						readyToFly: droneItem.d.readyToFly
						armed: droneItem.d.armed
						inFlight: droneItem.d.inFlight
						battery: droneItem.d.battery
						voltage: droneItem.d.voltage
					}

					Rectangle {
						Layout.fillWidth: true
						Layout.fillHeight: true
						color: S.Style.bgPanel
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
								color: S.Style.separator
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
								color: S.Style.separator
							}

							MissionWaypointList {
								Layout.preferredWidth: 230
								Layout.fillHeight: true
								items: droneItem.d.missionPlan ? droneItem.d.missionPlan.items : []
								currentWp: droneItem.d.wpCurrent
								totalWp: droneItem.d.wpTotal
								running: droneItem.d.missionRunning
								paused: droneItem.d.missionPaused
								finished: droneItem.d.missionFinished
								uploaded: droneItem.d.missionUploaded
								dirty: droneItem.d.missionDirty
								busy: droneItem.d.missionBusy
								busyText: droneItem.d.missionBusyText
								errorText: droneItem.d.missionErrorText
								connected: droneItem.d.connected
								readyToFly: droneItem.d.readyToFly
								returnHome: droneItem.d.missionPlan ? droneItem.d.missionPlan.returnHomeAfterMission : false
								landAtEnd: droneItem.d.missionPlan ? droneItem.d.missionPlan.landAfterMission : false
								defaultSpeed: droneItem.d.missionPlan ? droneItem.d.missionPlan.defaultSpeed : 0
								accentColor: S.Style.missionColor(droneItem.droneIndex)
								onStartClicked: droneItem.d.startMission()
								onPauseClicked: droneItem.d.pauseMission()
								onRestartClicked: droneItem.d.restartMission()
							}

							Rectangle {
								Layout.preferredWidth: 1
								Layout.fillHeight: true
								color: S.Style.separator
							}

							DroneTabArea {
								Layout.fillWidth: true
								Layout.fillHeight: true
								drone: droneItem.d
								cameraModel: root.cameraModel
								cameraDocks: root.cameraDocks
								logDock: droneItem.myLogDock
								panelIsPrimary: root.panelIsPrimary
								panelOpen: root.isOpen
							}

							// Altitude tape disabled for now.
							// AltitudeTape {
							// 	Layout.preferredWidth: 110
							// 	Layout.fillHeight: true
							// 	darkMode: true
							// 	altitude: droneItem.d.altitude
							// }
						}
					}
				}
			}
		}
	}
}
