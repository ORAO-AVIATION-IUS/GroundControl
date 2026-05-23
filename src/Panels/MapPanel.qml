pragma ComponentBehavior: Bound

import Agc.Components
import Agc.Mavlink
import Agc.Style
import QtPositioning
import QtQuick
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: dockRoot
	uniqueName: "mapPanel"
	title: qsTr("Map")

	property int mapMode: 0

	// per-drone target state: { droneIndex: { alt, locked } }
	property var _targetStore: ({})

	onSelectedDroneIndexChanged: {
		if (selectedDroneIndex >= 0) {
			var entry = _targetStore[selectedDroneIndex];
			if (entry && entry.locked)
				altTape.setTarget(entry.alt);
			else
				altTape.clearTarget();
		} else {
			altTape.clearTarget();
		}
	}

	readonly property int selectedDroneIndex: SwarmManager.selectedDroneIndex
	readonly property var selectedDrone: SwarmManager.selectedDrone

	function toMapDrones(list) {
		return list.map(d => ({
					"position": QtPositioning.coordinate(d.latitude, d.longitude),
					"altitude": d.altitude,
					"heading": d.heading
				}));
	}

	function toMapPaths(list) {
		return list.map(d => [QtPositioning.coordinate(d.latitude - 0.0002, d.longitude - 0.0004), QtPositioning.coordinate(d.latitude, d.longitude), QtPositioning.coordinate(d.latitude + 0.0003, d.longitude + 0.0006), QtPositioning.coordinate(d.latitude + 0.0007, d.longitude + 0.0011), QtPositioning.coordinate(d.latitude + 0.001, d.longitude + 0.0016)]);
	}

	Item {
		anchors.fill: parent

		MapView {
			id: mapView
			anchors.fill: parent

			threeD: mapSettings.is3d
			lightMode: !mapSettings.isDark
			satelliteMode: mapSettings.isSatellite
			drones: dockRoot.toMapDrones(SwarmManager.drones)
			flightPaths: dockRoot.toMapPaths(SwarmManager.drones)
		}

		Column {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.margins: Style.overlayMargin
			spacing: Style.sectionSpacing
			width: childrenRect.width

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

		Row {
			id: topRightOverlay
			z: 5
			anchors.top: parent.top
			anchors.right: parent.right
			anchors.margins: Style.overlayMargin
			spacing: Style.sectionSpacing

			Column {
				spacing: 4
				anchors.top: parent.top

				Repeater {
					model: SwarmManager.drones
					delegate: DroneStatusBadge {
						required property int index
						required property var modelData

						droneName: modelData.droneName
						connected: modelData.connected
						flightMode: modelData.flightMode
						armed: modelData.armed
						altitude: modelData.altitude
						batteryPercent: modelData.battery
						selected: index === dockRoot.selectedDroneIndex
						onClicked: SwarmManager.selectDrone(dockRoot.selectedDroneIndex === index ? -1 : index)
					}
				}
			}

			ButtonGroup {
				title: "ACTIONS"
				horizontal: true

				IconButton {
					id: armBtn
					property bool armed: dockRoot.selectedDrone ? dockRoot.selectedDrone.armed : false
					iconName: armed ? "security-high" : "security-low"
					label: armed ? "Disarm" : "Arm"
					labelColor: armed ? "#ff6b6b" : "#6bffb8"
					highlighted: armed
					enabled: dockRoot.selectedDrone !== null
					onClicked: if (dockRoot.selectedDrone)
						dockRoot.selectedDrone.armed ? dockRoot.selectedDrone.disarm() : dockRoot.selectedDrone.arm()
				}
				IconButton {
					iconName: "arrow-up-double"
					label: "Takeoff"
					labelColor: "#6bffb8"
					enabled: dockRoot.selectedDrone !== null
					onClicked: if (dockRoot.selectedDrone)
						dockRoot.selectedDrone.takeoff()
				}
				IconButton {
					iconName: "arrow-down-double"
					label: "Land"
					labelColor: "#ffd06b"
					enabled: dockRoot.selectedDrone !== null
					onClicked: if (dockRoot.selectedDrone)
						dockRoot.selectedDrone.land()
				}
				IconButton {
					iconName: "go-home-large"
					label: "RTH"
					labelColor: "#6bb8ff"
					enabled: dockRoot.selectedDrone !== null
					onClicked: if (dockRoot.selectedDrone)
						dockRoot.selectedDrone.rth()
				}
			}

			ButtonGroup {
				id: mapSettings
				title: "MAP"
				horizontal: true

				property bool is3d: false
				property bool isDark: true
				property bool isSatellite: false

				IconButton {
					iconName: mapSettings.is3d ? "map-gnomonic" : "map-flat"
					label: mapSettings.is3d ? "3D" : "2D"
					checkable: true
					checked: mapSettings.is3d
					onClicked: mapSettings.is3d = !mapSettings.is3d
				}
				IconButton {
					enabled: !mapSettings.isSatellite
					opacity: enabled ? 1.0 : 0.4
					iconName: mapSettings.isDark ? "weather-clear-night-symbolic" : "contrast"
					label: mapSettings.isDark ? "Dark" : "Light"
					checkable: true
					checked: mapSettings.isDark
					onClicked: mapSettings.isDark = !mapSettings.isDark
				}
				IconButton {
					iconName: mapSettings.isSatellite ? "kstars_satellites" : "map-globe"
					label: mapSettings.isSatellite ? "Sat" : "Street"
					checkable: true
					checked: mapSettings.isSatellite
					onClicked: mapSettings.isSatellite = !mapSettings.isSatellite
				}
			}
		}

		AltitudeTape {
			id: altTape
			enabled: dockRoot.selectedDroneIndex >= 0
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			altitude: dockRoot.selectedDrone ? dockRoot.selectedDrone.altitude : 0
			darkMode: mapSettings.isDark
			z: 1
			onTargetConfirmed: function (target) {
				if (dockRoot.selectedDroneIndex >= 0)
					dockRoot._targetStore[dockRoot.selectedDroneIndex] = {
						"alt": target,
						"locked": true
					};
				console.log("Target altitude confirmed:", target.toFixed(1), "m");
			}
			onTargetReset: {
				if (dockRoot.selectedDroneIndex >= 0)
					dockRoot._targetStore[dockRoot.selectedDroneIndex] = {
						"alt": 0,
						"locked": false
					};
				console.log("Target altitude reset");
			}
		}
	}
}
