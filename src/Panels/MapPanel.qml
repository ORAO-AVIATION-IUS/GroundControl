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

		// ── Top-right: Always-visible action blocks ──
		Row {
			anchors.top: parent.top
			anchors.right: parent.right
			anchors.margins: Style.overlayMargin
			spacing: Style.sectionSpacing

			// Actions — flight commands
			ButtonGroup {
				title: "ACTIONS"
				horizontal: true

				IconButton {
					id: armBtn
					iconName: droneManager.armed ? "security-high" : "security-low"
					label: droneManager.armed ? "Disarm" : "Arm"
					labelColor: droneManager.armed ? "#ff6b6b" : "#6bffb8"
					highlighted: droneManager.armed
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

				// Shared state
				property bool is3d: false
				property bool isDark: false

				function updateMap() {
					mapView.setPerspective(mapSettings.is3d);
					mapView.setTheme(mapSettings.isDark);
				}

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
