import Agc.Components
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: root
	uniqueName: "swarmPanel"
	title: qsTr("Drone Control")

	// ── Live state ──
	property bool live: droneManager.connected

	// ── Identity ──
	property string droneId: "M1"
	property string flightMode: live ? droneManager.flightMode : "STBY"
	property string activeMode: flightMode
	property bool armed: live ? droneManager.armed : false

	// ── Sensors / health (stubs — extend DroneManager later) ──
	property real cpuLoad: 38.0
	property bool sensorImu: live
	property bool sensorGps: live
	property bool sensorBaro: live
	property bool sensorMag: live

	readonly property bool readyToFly: sensorImu && sensorGps && sensorBaro && sensorMag && battery > 20

	// Dialog state
	property bool altitudeDialogVisible: false

	// ── Telemetry ──
	property real roll: live ? droneManager.roll : 0.0
	property real pitch: live ? droneManager.pitch : 0.0
	property real yaw: live ? droneManager.heading : 0.0

	property real airspeed: live ? droneManager.groundSpeed : 0.0 // proxy
	property real groundspeed: live ? droneManager.groundSpeed : 0.0
	property real climbRate: live ? droneManager.verticalSpeed : 0.0
	property int throttle: 0 // stub
	property real heading: live ? droneManager.heading : 0.0

	property real altRel: live ? droneManager.altitude : 0.0
	property real altMsl: live ? droneManager.altitude : 0.0 // proxy

	property real voltage: live ? droneManager.batteryVoltage : 12.60
	property real current: 0.0 // stub
	property int battery: live ? droneManager.batteryPercent : 92

	// ── Waypoint / comms (stubs) ──
	property int wpCurrent: 0
	property int wpTotal: 8
	property real wpDist: 0.0
	property int ping: 45

	readonly property int instSz: 82

	// ── Status log ──
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

	// Auto-log drone events (only connection state and errors —
	// action results are already logged by button handlers)
	Connections {
		target: droneManager
		function onConnectedChanged() {
			if (droneManager.connected)
				addLog("SYS", "Drone connected", "info");
			else
				addLog("SYS", "Drone disconnected", "warn");
		}
		function onError(message) {
			addLog(root.droneId, message, "err");
		}
	}

	Component.onCompleted: {
		addLog("SYS", "Drone control initialized", "info");
	}

	// ── Reusable components ──
	component TelRow: RowLayout {
		property string lbl: ""
		property string val: ""
		property bool warn: false
		Layout.fillWidth: true
		spacing: 0
		Text {
			text: lbl
			color: "#9090a0"
			font.pixelSize: 10
			font.family: "Segoe UI"
			Layout.preferredWidth: 46
		}
		Text {
			text: val
			Layout.fillWidth: true
			color: warn ? "#7a5a00" : "#1a1a2e"
			font.pixelSize: 10
			font.family: "Segoe UI"
			horizontalAlignment: Text.AlignRight
		}
	}

	component ActBtn: Rectangle {
		property string label: ""
		property color bgColor: "#f0f0f4"
		property color txtColor: "#3a4a5a"
		signal tapped
		Layout.fillWidth: true
		height: 26
		radius: 0
		color: ma.pressed ? Qt.darker(bgColor, 1.12) : ma.containsMouse ? Qt.darker(bgColor, 1.06) : bgColor
		border.color: Qt.darker(bgColor, 1.16)
		border.width: 1
		Text {
			anchors.centerIn: parent
			text: label
			color: txtColor
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

	Rectangle {
		anchors.fill: parent
		color: "#ffffff"
		property var kddockwidgets_min_size: Qt.size(900, 250)

		ColumnLayout {
			anchors.fill: parent
			spacing: 0

			// ── Header ──
			Item {
				Layout.fillWidth: true
				height: 44

				RowLayout {
					anchors.fill: parent
					anchors.leftMargin: 14
					anchors.rightMargin: 14
					spacing: 0

					Text {
						text: root.droneId
						font.pixelSize: 15
						font.bold: true
						font.family: "Segoe UI"
						color: "#1a1a2e"
						Layout.alignment: Qt.AlignVCenter
					}

					Rectangle {
						width: 1
						height: 20
						color: "#e4e4e8"
						Layout.alignment: Qt.AlignVCenter
						Layout.leftMargin: 12
						Layout.rightMargin: 12
					}

					Text {
						text: root.readyToFly ? "Ready To Fly" : "Not Ready"
						font.pixelSize: 15
						font.bold: true
						font.family: "Segoe UI"
						color: root.readyToFly ? "#1e7a40" : "#8a2010"
						Layout.alignment: Qt.AlignVCenter
					}

					Rectangle {
						width: 1
						height: 20
						color: "#e4e4e8"
						Layout.alignment: Qt.AlignVCenter
						Layout.leftMargin: 12
						Layout.rightMargin: 12
					}

					Text {
						text: root.flightMode
						font.pixelSize: 15
						font.bold: true
						font.family: "Segoe UI"
						color: modeMa.containsMouse ? "#1a50a0" : "#344878"
						Layout.alignment: Qt.AlignVCenter

						MouseArea {
							id: modeMa
							anchors.fill: parent
							hoverEnabled: true
							enabled: !root.live
							onClicked: {
								const modes = ["STBY", "GUIDED", "AUTO", "RTL", "LOITER", "LAND"];
								root.setMode(modes[(modes.indexOf(root.activeMode) + 1) % modes.length]);
							}
						}
					}

					Item {
						Layout.fillWidth: true
					}

					Rectangle {
						Layout.alignment: Qt.AlignVCenter
						Layout.rightMargin: 6
						width: 76
						height: 30
						radius: 0
						color: "#f6f8fa"
						border.color: "#e0e4ea"
						border.width: 1

						Rectangle {
							width: 3
							height: parent.height
							radius: 0
							color: root.battery > 50 ? "#1e7a40" : root.battery > 20 ? "#c08000" : "#c02010"
						}

						Column {
							anchors.left: parent.left
							anchors.leftMargin: 9
							anchors.verticalCenter: parent.verticalCenter
							spacing: 1
							Text {
								text: "BATTERY"
								font.pixelSize: 8
								font.family: "Segoe UI"
								color: "#9090a0"
							}
							Text {
								text: root.battery + "%  " + root.voltage.toFixed(1) + " V"
								font.pixelSize: 9
								font.bold: true
								font.family: "Segoe UI"
								color: "#1a1a2e"
							}
						}
					}

					Rectangle {
						Layout.alignment: Qt.AlignVCenter
						Layout.rightMargin: 12
						width: 76
						height: 30
						radius: 0
						color: root.armed ? "#edf7f1" : "#f6f6f8"
						border.color: root.armed ? "#8ecaaa" : "#dcdce4"
						border.width: 1

						Rectangle {
							width: 3
							height: parent.height
							radius: 0
							color: root.armed ? "#1e7a40" : "#c0c4cc"
						}

						Column {
							anchors.left: parent.left
							anchors.leftMargin: 9
							anchors.verticalCenter: parent.verticalCenter
							spacing: 1
							Text {
								text: "STATUS"
								font.pixelSize: 8
								font.family: "Segoe UI"
								color: "#9090a0"
							}
							Text {
								text: root.armed ? "ARMED" : "DISARMED"
								font.pixelSize: 9
								font.bold: true
								font.family: "Segoe UI"
								color: root.armed ? "#1a6030" : "#606878"
							}
						}
					}
				}

				Rectangle {
					anchors.bottom: parent.bottom
					width: parent.width
					height: 1
					color: "#e4e4e8"
				}
			}

			// ── Main content ──
			Rectangle {
				Layout.fillWidth: true
				Layout.fillHeight: true
				color: "#ffffff"
				clip: true

				RowLayout {
					anchors.fill: parent
					spacing: 0

					// Telemetry
					Item {
						Layout.preferredWidth: 150
						Layout.fillHeight: true

						ColumnLayout {
							anchors.fill: parent
							anchors.margins: 10
							anchors.topMargin: 10
							spacing: 3

							Text {
								text: "TELEMETRY"
								color: "#a0a8b0"
								font.pixelSize: 9
								font.bold: true
								font.letterSpacing: 1.4
								font.family: "Segoe UI"
								Layout.bottomMargin: 4
							}

							TelRow {
								lbl: "ROLL"
								val: root.roll.toFixed(1) + " °"
							}
							TelRow {
								lbl: "PITCH"
								val: root.pitch.toFixed(1) + " °"
							}
							TelRow {
								lbl: "YAW"
								val: root.yaw.toFixed(1) + " °"
							}
							TelRow {
								lbl: "ALT"
								val: root.altRel.toFixed(1) + " m"
							}
							TelRow {
								lbl: "CLIMB"
								val: root.climbRate.toFixed(1) + " m/s"
							}
							TelRow {
								lbl: "GSPD"
								val: root.groundspeed.toFixed(1) + " m/s"
							}
							TelRow {
								lbl: "HDG"
								val: root.heading.toFixed(1) + " °"
							}
							TelRow {
								lbl: "BAT"
								val: root.battery + " %"
								warn: root.battery < 20
							}
							TelRow {
								lbl: "VOLT"
								val: root.voltage.toFixed(2) + " V"
								warn: root.voltage < 11.0
							}
							TelRow {
								lbl: "PING"
								val: root.ping + " ms"
								warn: root.ping > 200
							}

							Item {
								Layout.fillHeight: true
							}
						}
					}

					Rectangle {
						width: 1
						Layout.fillHeight: true
						color: "#e8e8ec"
					}

					// Instruments
					Item {
						Layout.preferredWidth: root.instSz * 3 + 16
						Layout.fillHeight: true

						GridLayout {
							anchors.top: parent.top
							anchors.horizontalCenter: parent.horizontalCenter
							anchors.topMargin: 10
							columns: 3
							rowSpacing: 6
							columnSpacing: 6

							AttitudeIndicator {
								Layout.preferredWidth: root.instSz
								Layout.preferredHeight: root.instSz
								pitch: root.pitch
								roll: root.roll
							}
							AirspeedIndicator {
								Layout.preferredWidth: root.instSz
								Layout.preferredHeight: root.instSz
								airspeedMs: root.airspeed
							}
							TurnController {
								Layout.preferredWidth: root.instSz
								Layout.preferredHeight: root.instSz
								yawspeed: live ? droneManager.yawspeed : 0.0
								yacc: live ? droneManager.yacc : 0.0
							}
							CompassIndicator {
								Layout.preferredWidth: root.instSz
								Layout.preferredHeight: root.instSz
								heading: root.heading
							}
							HeadingIndicator {
								Layout.preferredWidth: root.instSz
								Layout.preferredHeight: root.instSz
								heading: root.heading
							}

							Rectangle {
								Layout.preferredWidth: root.instSz
								Layout.preferredHeight: root.instSz
								color: "#f8f8fa"
								radius: 0
								border.color: "#e8e8ec"
								border.width: 1
								Column {
									anchors.centerIn: parent
									spacing: 5
									BatteryIndicator {
										width: 54
										height: 24
										anchors.horizontalCenter: parent.horizontalCenter
										batteryPercent: root.battery
									}
									Text {
										anchors.horizontalCenter: parent.horizontalCenter
										text: root.battery + "%"
										color: root.battery > 50 ? "#1e7a40" : root.battery > 20 ? "#7a5a00" : "#8a2010"
										font.pixelSize: 11
										font.bold: true
										font.family: "Segoe UI"
									}
									Text {
										anchors.horizontalCenter: parent.horizontalCenter
										text: root.voltage.toFixed(2) + " V"
										color: "#9090a0"
										font.pixelSize: 9
										font.family: "Segoe UI"
									}
								}
							}
						}
					}

					Rectangle {
						width: 1
						Layout.fillHeight: true
						color: "#e8e8ec"
					}

					// Controls
					Item {
						Layout.preferredWidth: 230
						Layout.fillHeight: true

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
									enabled: live && !droneManager.armed
									opacity: enabled ? 1.0 : 0.38
									onTapped: {
										droneManager.arm();
										addLog(root.droneId, "ARM command sent", "info");
									}
								}
								ActBtn {
									label: "DISARM"
									bgColor: "#fdf0ee"
									txtColor: "#6a1e1e"
									enabled: live && droneManager.armed
									opacity: enabled ? 1.0 : 0.38
									onTapped: {
										droneManager.disarm();
										addLog(root.droneId, "DISARM command sent", "info");
									}
								}
								ActBtn {
									label: "TAKEOFF"
									bgColor: "#edf2fa"
									txtColor: "#1a3060"
									enabled: live && droneManager.armed && !droneManager.inAir
									opacity: enabled ? 1.0 : 0.38
									onTapped: {
										droneManager.takeoff();
										addLog(root.droneId, "TAKEOFF command sent", "info");
									}
								}
								ActBtn {
									label: "LAND"
									bgColor: "#faf4ec"
									txtColor: "#4a3010"
									enabled: live && droneManager.inAir
									opacity: enabled ? 1.0 : 0.38
									onTapped: {
										droneManager.land();
										addLog(root.droneId, "LAND command sent", "info");
									}
								}
								ActBtn {
									label: "RTL"
									bgColor: "#f0f0f4"
									txtColor: "#3a4a5a"
									enabled: live && droneManager.inAir
									opacity: enabled ? 1.0 : 0.38
									onTapped: {
										droneManager.returnToLaunch();
										addLog(root.droneId, "RTL command sent", "info");
									}
								}
								ActBtn {
									label: "CONFIG"
									bgColor: "#f0f0f4"
									txtColor: "#3a4a5a"
									onTapped: root.altitudeDialogVisible = true
								}
							}

							Rectangle {
								Layout.fillWidth: true
								height: 1
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
										required property string modelData
										Layout.fillWidth: true
										height: 26
										radius: 0
										color: root.activeMode === modelData ? "#e8f0fa" : modeArea.containsMouse ? "#f4f6fa" : "#f8f8fa"
										border.color: root.activeMode === modelData ? "#4070b0" : "#dcdce4"
										border.width: 1
										Text {
											anchors.centerIn: parent
											text: modelData
											color: root.activeMode === modelData ? "#1a4890" : "#4a5060"
											font.pixelSize: 11
											font.bold: root.activeMode === modelData
											font.family: "Segoe UI"
										}
										MouseArea {
											id: modeArea
											anchors.fill: parent
											hoverEnabled: true
											enabled: !root.live
											onClicked: root.setMode(modelData)
										}
									}
								}
							}

							Item {
								Layout.fillHeight: true
							}
						}
					}

					Rectangle {
						width: 1
						Layout.fillHeight: true
						color: "#e8e8ec"
					}

					// Status Log
					Item {
						Layout.fillWidth: true
						Layout.fillHeight: true

						ColumnLayout {
							anchors.fill: parent
							anchors.margins: 12
							spacing: 0

							RowLayout {
								Layout.fillWidth: true
								Layout.bottomMargin: 6
								Text {
									text: "STATUS LOG"
									color: "#a0a8b0"
									font.pixelSize: 9
									font.bold: true
									font.letterSpacing: 1.4
									font.family: "Segoe UI"
								}
								Item {
									Layout.fillWidth: true
								}
								Text {
									text: "CLR"
									color: clrArea.containsMouse ? "#3a4a5a" : "#b0b8c0"
									font.pixelSize: 9
									font.family: "Segoe UI"
									MouseArea {
										id: clrArea
										anchors.fill: parent
										hoverEnabled: true
										onClicked: logModel.clear()
									}
								}
							}

							Rectangle {
								Layout.fillWidth: true
								height: 1
								color: "#e8e8ec"
							}

							ListView {
								id: logView
								Layout.fillWidth: true
								Layout.fillHeight: true
								model: logModel
								clip: true
								spacing: 2
								Layout.topMargin: 6

								delegate: RowLayout {
									required property string ts
									required property string src
									required property string msg
									required property string level
									width: logView.width
									spacing: 5

									Text {
										text: ts
										color: "#b0b8c4"
										font.pixelSize: 9
										font.family: "Segoe UI"
									}
									Text {
										text: "[" + src + "]"
										width: 36
										color: src === "SYS" ? "#2a5080" : "#6a4010"
										font.pixelSize: 9
										font.bold: true
										font.family: "Segoe UI"
									}
									Text {
										Layout.fillWidth: true
										text: msg
										color: level === "err" ? "#8a2010" : level === "warn" ? "#7a5a00" : "#4a5060"
										font.pixelSize: 9
										font.family: "Segoe UI"
										elide: Text.ElideRight
									}
								}
							}
						}
					}

					Rectangle {
						width: 1
						Layout.fillHeight: true
						color: "#e8e8ec"
					}

					// AltitudeTape — far right
					AltitudeTape {
						Layout.preferredWidth: 90
						Layout.fillHeight: true
						altitude: root.altRel
					}
				}
			}
		}

		// Altitude dialog overlay
		Rectangle {
			anchors.fill: parent
			color: Qt.rgba(0, 0, 0, 0.35)
			visible: root.altitudeDialogVisible
			z: 100

			MouseArea {
				anchors.fill: parent
				onClicked: root.altitudeDialogVisible = false
			}

			Rectangle {
				anchors.centerIn: parent
				width: 260
				height: 150
				color: "#ffffff"
				radius: 4
				border.color: "#e0e0e0"
				border.width: 1

				ColumnLayout {
					anchors.fill: parent
					anchors.margins: 16
					spacing: 12

					Text {
						text: "Set Target Altitude"
						font.pixelSize: 14
						font.bold: true
						font.family: "Segoe UI"
						color: "#1a1a2e"
					}

					TextField {
						id: altitudeInput
						Layout.fillWidth: true
						placeholderText: "e.g. 10.0"
						text: root.altRel.toFixed(1)
						validator: DoubleValidator {
							bottom: 0
							top: 500
							decimals: 1
						}
					}

					RowLayout {
						Layout.fillWidth: true
						spacing: 8

						Rectangle {
							Layout.fillWidth: true
							height: 28
							radius: 0
							color: cancelMa.pressed ? Qt.darker("#f0f0f4", 1.12) : cancelMa.containsMouse ? Qt.darker("#f0f0f4", 1.06) : "#f0f0f4"
							border.color: Qt.darker("#f0f0f4", 1.16)
							border.width: 1
							Text {
								anchors.centerIn: parent
								text: "CANCEL"
								color: "#3a4a5a"
								font.pixelSize: 11
								font.bold: true
								font.family: "Segoe UI"
							}
							MouseArea {
								id: cancelMa
								anchors.fill: parent
								hoverEnabled: true
								onClicked: root.altitudeDialogVisible = false
							}
						}

						Rectangle {
							Layout.fillWidth: true
							height: 28
							radius: 0
							color: okMa.pressed ? Qt.darker("#edf7f1", 1.12) : okMa.containsMouse ? Qt.darker("#edf7f1", 1.06) : "#edf7f1"
							border.color: Qt.darker("#edf7f1", 1.16)
							border.width: 1
							Text {
								anchors.centerIn: parent
								text: "OK"
								color: "#1a5830"
								font.pixelSize: 11
								font.bold: true
								font.family: "Segoe UI"
							}
							MouseArea {
								id: okMa
								anchors.fill: parent
								hoverEnabled: true
								onClicked: {
									var val = parseFloat(altitudeInput.text);
									if (!isNaN(val) && val >= 0) {
										droneManager.setAltitude(val);
										addLog(root.droneId, "Set altitude to " + val.toFixed(1) + " m", "info");
										root.altitudeDialogVisible = false;
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
