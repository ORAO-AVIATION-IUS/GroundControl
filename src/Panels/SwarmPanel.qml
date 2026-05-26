import Agc.Components
import Agc.Log
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: root
	uniqueName: "swarmPanel"
	title: qsTr("Drone Control")

	signal detachLogRequested(string source)

	property bool logDetached: false

	property string droneId: "1"

	property bool armed: false
	property string flightMode: ""
	property string activeMode: ""

	property real cpuLoad: 0.0
	property bool sensorImu: false
	property bool sensorGps: false
	property bool sensorBaro: false
	property bool sensorMag: false

	property real roll: 0.0
	property real pitch: 0.0
	property real yaw: 0.0

	property real airspeed: 0.0
	property real groundspeed: 0.0
	property real climbRate: 0.0
	property int throttle: 0
	property real heading: 0.0

	property real altRel: 0.0
	property real altMsl: 0.0

	property real voltage: 0.0
	property real current: 0.0
	property int battery: 0

	property int wpCurrent: 0
	property int wpTotal: 0
	property real wpDist: 0.0

	property int ping: 0

	readonly property bool readyToFly: sensorImu && sensorGps && sensorBaro && sensorMag && battery > 20

	readonly property string logSourceName: "drone-" + droneId

	function addLog(msg, level) {
		const lvlMap = { "info": 1, "warn": 2, "warning": 2, "err": 3, "error": 3 };
		const lvl = lvlMap[level] !== undefined ? lvlMap[level] : 1;
		LogManager.emitLog(root.logSourceName, lvl, msg);
	}

	function armDrone() {
		root.armed = true;
		root.flightMode = root.activeMode;
		addLog("Armed - motor check OK", "info");
	}

	function disarmDrone() {
		root.armed = false;
		root.flightMode = "STBY";
		root.activeMode = "STBY";
		addLog("Disarmed", "info");
	}

	function setMode(mode) {
		root.activeMode = mode;
		if (root.armed)
			root.flightMode = mode;
		addLog("Mode changed to " + mode, "info");
	}

	function cycleMode() {
		const modes = ["STBY", "GUIDED", "AUTO", "RTL", "LOITER", "LAND"];
		root.setMode(modes[(modes.indexOf(root.activeMode) + 1) % modes.length]);
	}

	Rectangle {
		anchors.fill: parent
		color: "#ffffff"

		ColumnLayout {
			anchors.fill: parent
			spacing: 0

			SwarmHeader {
				Layout.fillWidth: true
				droneId: root.droneId
				activeMode: root.activeMode
				readyToFly: root.readyToFly
				armed: root.armed
				battery: root.battery
				voltage: root.voltage
				onModeClicked: root.cycleMode()
			}

			Rectangle {
				Layout.fillWidth: true
				Layout.fillHeight: true
				color: "#ffffff"
				clip: true

				SplitView {
					anchors.fill: parent
					orientation: Qt.Horizontal

					handle: Rectangle {
						implicitWidth: 4
						implicitHeight: 4
						color: SplitHandle.pressed ? "#9aa7b4"
						     : SplitHandle.hovered ? "#c8d0d8"
						     : "#e8e8ec"
					}

					TelemetrySidebar {
						SplitView.preferredWidth: 150
						SplitView.minimumWidth: 120
						roll: root.roll
						pitch: root.pitch
						yaw: root.yaw
						altRel: root.altRel
						climbRate: root.climbRate
						groundspeed: root.groundspeed
						heading: root.heading
						battery: root.battery
						voltage: root.voltage
						ping: root.ping
					}

					InstrumentGrid {
						SplitView.fillWidth: true
						SplitView.minimumWidth: 240
						SplitView.preferredWidth: 380
						pitch: root.pitch
						roll: root.roll
						heading: root.heading
					}

					DroneControls {
						SplitView.preferredWidth: 230
						SplitView.minimumWidth: 200
						armed: root.armed
						activeMode: root.activeMode
						droneId: root.droneId
						onArmClicked: root.armDrone()
						onDisarmClicked: root.disarmDrone()
						onTakeoffClicked: root.addLog("TAKEOFF command sent", "info")
						onLandClicked: root.addLog("LAND command sent", "info")
						onResetClicked: root.addLog("RESET command sent", "warn")
						onConfigClicked: root.addLog("CONFIG command sent", "info")
						onModeSelected: function (mode) {
							root.setMode(mode);
						}
					}

					ColumnLayout {
						id: tabsArea
						SplitView.fillWidth: true
						SplitView.minimumWidth: 280
						SplitView.preferredWidth: 420
						spacing: 0

						property int _preDetachIndex: 0

						Connections {
							target: root
							function onLogDetachedChanged() {
								if (root.logDetached) {
									tabsArea._preDetachIndex = tabBar.currentIndex;
									tabBar.currentIndex = 1;
								} else {
									tabBar.currentIndex = tabsArea._preDetachIndex;
								}
							}
						}

						RowLayout {
							Layout.fillWidth: true
							spacing: 0

							TabBar {
								id: tabBar
								Layout.fillWidth: true
								currentIndex: 0

								TabButton {
									visible: !root.logDetached
									width: visible ? implicitWidth : 0
									text: qsTr("Log")
								}
								TabButton {
									text: qsTr("Cameras")
								}
							}

							Button {
								Layout.alignment: Qt.AlignVCenter
								Layout.rightMargin: 6
								visible: root.logDetached
								text: qsTr("⤓ Re-attach log")
								onClicked: root.logDetached = false
								ToolTip.visible: hovered
								ToolTip.text: qsTr("Return the log to the drone panel")
							}
						}

						StackLayout {
							Layout.fillWidth: true
							Layout.fillHeight: true
							currentIndex: tabBar.currentIndex

							LogView {
								id: embeddedLog
								visible: !root.logDetached
								boundSource: root.logSourceName
								pinned: true
								showSourceFilter: false
								showDetach: true
								onDetachRequested: root.detachLogRequested(boundSource)
							}

							Rectangle {
								id: camerasPlaceholder
								color: "#fafbfc"
								border.color: "#e8e8ec"

								Text {
									id: phTitle
									anchors.horizontalCenter: parent.horizontalCenter
									anchors.verticalCenter: parent.verticalCenter
									anchors.verticalCenterOffset: -10
									text: qsTr("Cameras for %1").arg(root.droneId)
									horizontalAlignment: Text.AlignHCenter
									color: "#9098a4"
									font.pixelSize: 13
									font.bold: true
									font.family: "Segoe UI"
								}
								Text {
									anchors.horizontalCenter: parent.horizontalCenter
									anchors.top: phTitle.bottom
									anchors.topMargin: 4
									text: qsTr("(handled by camera module)")
									horizontalAlignment: Text.AlignHCenter
									color: "#b0b8c0"
									font.pixelSize: 11
									font.family: "Segoe UI"
								}
							}
						}
					}
				}
			}
		}
	}
}
