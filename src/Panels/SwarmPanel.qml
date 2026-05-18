import Agc.Components
import QtQuick
import QtQuick.Layouts
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: root
	uniqueName: "swarmPanel"
	title: qsTr("Drone Control")

	property string droneId: "--"
	property string flightMode: ""
	property bool armed: false

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

	property string activeMode: ""
	readonly property bool readyToFly: sensorImu && sensorGps && sensorBaro && sensorMag && battery > 20

	ListModel {
		id: logModel
	}

	function addLog(src, msg, level) {
		const lvl = (typeof level !== "undefined") ? level : "info";
		const d = new Date();
		const ts = String(d.getHours()).padStart(2, '0') + ":" + String(d.getMinutes()).padStart(2, '0') + ":" + String(d.getSeconds()).padStart(2, '0');
		logModel.insert(0, {
			"ts": ts,
			"src": src,
			"msg": msg,
			"level": lvl
		});
		if (logModel.count > 200)
			logModel.remove(200, logModel.count - 200);
	}

	function armDrone() {
		root.armed = true;
		root.flightMode = root.activeMode;
		addLog(root.droneId, "Armed — motor check OK", "info");
	}

	function disarmDrone() {
		root.armed = false;
		root.flightMode = "STBY";
		root.activeMode = "STBY";
		addLog(root.droneId, "Disarmed", "info");
	}

	function setMode(mode) {
		root.activeMode = mode;
		if (root.armed) {
			root.flightMode = mode;
			addLog(root.droneId, "Mode changed to " + mode, "info");
		}
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

				RowLayout {
					anchors.fill: parent
					spacing: 0

					TelemetrySidebar {
						Layout.preferredWidth: 150
						Layout.fillHeight: true
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

					Rectangle {
						Layout.preferredWidth: 1
						Layout.fillHeight: true
						color: "#e8e8ec"
					}

					InstrumentGrid {
						Layout.fillWidth: true
						Layout.fillHeight: true
						pitch: root.pitch
						roll: root.roll
						heading: root.heading
					}

					Rectangle {
						Layout.preferredWidth: 1
						Layout.fillHeight: true
						color: "#e8e8ec"
					}

					DroneControls {
						Layout.preferredWidth: 230
						Layout.fillHeight: true
						armed: root.armed
						activeMode: root.activeMode
						droneId: root.droneId
						onArmClicked: root.armDrone()
						onDisarmClicked: root.disarmDrone()
						onTakeoffClicked: root.addLog(root.droneId, "TAKEOFF command sent", "info")
						onLandClicked: root.addLog(root.droneId, "LAND command sent", "info")
						onResetClicked: root.addLog(root.droneId, "RESET command sent", "warn")
						onConfigClicked: root.addLog(root.droneId, "CONFIG command sent", "info")
						onModeSelected: function (mode) {
							root.setMode(mode);
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
						altitude: root.altRel
					}
				}
			}
		}
	}
}
