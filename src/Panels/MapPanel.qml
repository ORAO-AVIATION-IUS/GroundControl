import Agc.Components
import Agc.Style
import QtQuick
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: dockRoot
	uniqueName: "mapPanel"
	title: qsTr("Map")

	property int mapMode: 0 // 0=Explore, 1=Plan, 2=Fly

	Item {
		anchors.fill: parent

		MapView {
			id: mapView
			anchors.fill: parent
		}

		// ── Left: Mode selector + contextual tools ──
		Column {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.margins: Style.overlayMargin
			spacing: Style.sectionSpacing
			width: childrenRect.width

			// Mode selector
			ButtonGroup {
				title: "MODE"
				IconButton {
					iconName: "compass"
					label: "Explore"
					checked: dockRoot.mapMode === 0
					onClicked: dockRoot.mapMode = 0
				}
				IconButton {
					iconName: "routeplanning"
					label: "Plan"
					checked: dockRoot.mapMode === 1
					onClicked: dockRoot.mapMode = 1
				}
				IconButton {
					iconName: "flightmode-on"
					label: "Fly"
					checked: dockRoot.mapMode === 2
					onClicked: dockRoot.mapMode = 2
				}
			}

			// Plan tools — only visible in Plan mode
			ButtonGroup {
				title: "TOOLS"
				visible: dockRoot.mapMode === 1
				opacity: visible ? 1 : 0
				Behavior on opacity {
					NumberAnimation {
						duration: 150
					}
				}

				IconButton {
					iconName: "flag-black"
					label: "Waypoint"
					onClicked: console.log("Waypoint tool")
				}
				IconButton {
					iconName: "draw-polygon"
					label: "Survey"
					onClicked: console.log("Survey tool")
				}
				IconButton {
					iconName: "draw-rectangle"
					label: "Fence"
					onClicked: console.log("Geofence tool")
				}
				IconButton {
					iconName: "measure"
					label: "Measure"
					onClicked: console.log("Measure tool")
				}
			}

			// Fly tools — only visible in Fly mode
			ButtonGroup {
				title: "TRACK"
				visible: dockRoot.mapMode === 2
				opacity: visible ? 1 : 0
				Behavior on opacity {
					NumberAnimation {
						duration: 150
					}
				}

				IconButton {
					iconName: "crosshairs"
					label: "Follow"
					onClicked: console.log("Follow vehicle")
				}
				IconButton {
					iconName: "mark-location"
					label: "Point"
					onClicked: console.log("Set target point")
				}
				IconButton {
					iconName: "go-home-large"
					label: "Home"
					onClicked: console.log("Show RTH point")
				}
			}
		}

		// ── Top-right: Drone status + actions + map settings ──
		Row {
			anchors.top: parent.top
			anchors.right: parent.right
			anchors.margins: Style.overlayMargin
			spacing: Style.sectionSpacing

			// Drone status badge (left of actions)
			Rectangle {
				visible: droneManager.connected
				opacity: visible ? 1.0 : 0.0
				Behavior on opacity {
					NumberAnimation {
						duration: 200
					}
				}
				width: statusRow.implicitWidth + 16
				height: statusRow.implicitHeight + 10
				color: "#1c1f26"
				radius: 5

				Row {
					id: statusRow
					anchors.centerIn: parent
					spacing: 10

					// Connection dot
					Rectangle {
						width: 6
						height: 6
						radius: 3
						color: "#2ecc71"
						anchors.verticalCenter: parent.verticalCenter
					}

					// Flight mode
					Text {
						text: droneManager.flightMode
						color: "#cdd6e0"
						font.pixelSize: 8
						font.bold: true
						anchors.verticalCenter: parent.verticalCenter
					}

					// Armed indicator
					Text {
						text: droneManager.armed ? "ARMED" : "DISARMED"
						color: droneManager.armed ? "#e74c3c" : "#6b7a8d"
						font.pixelSize: 7
						font.bold: true
						anchors.verticalCenter: parent.verticalCenter
					}

					// Altitude
					Text {
						text: droneManager.altitude.toFixed(0) + " m"
						color: "#8cb4f0"
						font.pixelSize: 8
						anchors.verticalCenter: parent.verticalCenter
					}

					// Battery
					Text {
						text: droneManager.batteryPercent.toFixed(0) + "%"
						color: droneManager.batteryPercent > 30 ? "#2ecc71" : droneManager.batteryPercent > 15 ? "#f39c12" : "#e74c3c"
						font.pixelSize: 8
						font.bold: true
						anchors.verticalCenter: parent.verticalCenter
					}
				}
			}

			// Actions — flight commands
			ButtonGroup {
				id: actionsGroup
				title: "ACTIONS"
				horizontal: true

				IconButton {
					iconName: droneManager.armed ? "security-high" : "security-low"
					label: droneManager.armed ? "Disarm" : "Arm"
					labelColor: droneManager.armed ? "#ff6b6b" : "#6bffb8"
					highlighted: droneManager.armed
					enabled: droneManager.connected
					onClicked: droneManager.armed ? droneManager.disarm() : droneManager.arm()
				}
				IconButton {
					iconName: "arrow-up-double"
					label: "Takeoff"
					labelColor: "#6bffb8"
					enabled: droneManager.connected && droneManager.armed && !droneManager.inAir
					onClicked: droneManager.takeoff()
				}
				IconButton {
					iconName: "arrow-down-double"
					label: "Land"
					labelColor: "#ffd06b"
					enabled: droneManager.connected && droneManager.inAir
					onClicked: droneManager.land()
				}
				IconButton {
					iconName: "go-home-large"
					label: "RTH"
					labelColor: "#6bb8ff"
					enabled: droneManager.connected && droneManager.inAir
					onClicked: droneManager.returnToLaunch()
				}
			}

			// Map settings
			ButtonGroup {
				id: mapSettings
				title: "MAP"
				horizontal: true

				property bool is3d: true
				property bool isDark: false

				function updateMap() {
					mapView.setPerspective(mapSettings.is3d);
					mapView.setTheme(mapSettings.isDark);
				}

				Component.onCompleted: updateMap()

				IconButton {
					iconName: mapSettings.is3d ? "map-gnomonic" : "map-flat"
					label: mapSettings.is3d ? "3D" : "2D"
					checkable: true
					checked: mapSettings.is3d
					onClicked: {
						mapSettings.is3d = !mapSettings.is3d;
						mapSettings.updateMap();
					}
				}
				IconButton {
					iconName: mapSettings.isDark ? "weather-clear-night-symbolic" : "contrast"
					label: mapSettings.isDark ? "Dark" : "Light"
					checkable: true
					checked: mapSettings.isDark
					onClicked: {
						mapSettings.isDark = !mapSettings.isDark;
						mapSettings.updateMap();
					}
				}
			}
		}
	}
}
