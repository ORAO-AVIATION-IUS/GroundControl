pragma ComponentBehavior: Bound

import Agc.Components
import Agc.Style
import QtPositioning
import QtQuick
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: dockRoot
	uniqueName: "mapPanel"
	title: qsTr("Map")

	property int mapMode: 0
	property int selectedDroneIndex: -1

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

	// swap with DroneManager later
	property var drones: [
		{
			"droneName": "SITL-1",
			"connected": true,
			"flightMode": "POSCTL",
			"armed": true,
			"altitude": 120.0,
			"batteryPercent": 87.0,
			"lat": 41.0082,
			"lon": 28.9784,
			"heading": 45
		},
		{
			"droneName": "SITL-2",
			"connected": true,
			"flightMode": "STABILIZED",
			"armed": false,
			"altitude": 0.0,
			"batteryPercent": 64.0,
			"lat": 41.0078,
			"lon": 28.9788,
			"heading": -30
		}
	]

	// TMP function
	function toMapDrones(list) {
		return list.map(d => ({
					"position": QtPositioning.coordinate(d.lat, d.lon),
					"altitude": d.altitude,
					"heading": d.heading
				}));
	}

	// TMP function
	function toMapPaths(list) {
		return list.map(d => [QtPositioning.coordinate(d.lat - 0.0002, d.lon - 0.0004), QtPositioning.coordinate(d.lat, d.lon), QtPositioning.coordinate(d.lat + 0.0003, d.lon + 0.0006), QtPositioning.coordinate(d.lat + 0.0007, d.lon + 0.0011), QtPositioning.coordinate(d.lat + 0.001, d.lon + 0.0016)]);
	}

	Item {
		anchors.fill: parent

		MapView {
			id: mapView
			anchors.fill: parent

			threeD: mapSettings.is3d
			lightMode: !mapSettings.isDark
			drones: dockRoot.toMapDrones(dockRoot.drones)
			flightPaths: dockRoot.toMapPaths(dockRoot.drones)
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
					model: dockRoot.drones
					delegate: DroneStatusBadge {
						required property int index
						required property var modelData

						droneName: modelData.droneName
						connected: modelData.connected
						flightMode: modelData.flightMode
						armed: modelData.armed
						altitude: modelData.altitude
						batteryPercent: modelData.batteryPercent
						selected: index === dockRoot.selectedDroneIndex
						onClicked: dockRoot.selectedDroneIndex = dockRoot.selectedDroneIndex === index ? -1 : index
					}
				}
			}

			ButtonGroup {
				title: "ACTIONS"
				horizontal: true

				IconButton {
					id: armBtn
					property bool armed: false
					iconName: armed ? "security-high" : "security-low"
					label: armed ? "Disarm" : "Arm"
					labelColor: armed ? "#ff6b6b" : "#6bffb8"
					highlighted: armed
					onClicked: {
						armed = !armed;
						console.log(armed ? "Armed" : "Disarmed");
					}
				}
				IconButton {
					iconName: "arrow-up-double"
					label: "Takeoff"
					labelColor: "#6bffb8"
					onClicked: console.log("Takeoff")
				}
				IconButton {
					iconName: "arrow-down-double"
					label: "Land"
					labelColor: "#ffd06b"
					onClicked: console.log("Land")
				}
				IconButton {
					iconName: "go-home-large"
					label: "RTH"
					labelColor: "#6bb8ff"
					onClicked: console.log("Return to Home")
				}
			}

			ButtonGroup {
				id: mapSettings
				title: "MAP"
				horizontal: true

				property bool is3d: false
				property bool isDark: true

				IconButton {
					iconName: mapSettings.is3d ? "map-gnomonic" : "map-flat"
					label: mapSettings.is3d ? "3D" : "2D"
					checkable: true
					checked: mapSettings.is3d
					onClicked: mapSettings.is3d = !mapSettings.is3d
				}
				IconButton {
					iconName: mapSettings.isDark ? "weather-clear-night-symbolic" : "contrast"
					label: mapSettings.isDark ? "Dark" : "Light"
					checkable: true
					checked: mapSettings.isDark
					onClicked: mapSettings.isDark = !mapSettings.isDark
				}
			}
		}

		AltitudeTape {
			id: altTape
			enabled: dockRoot.selectedDroneIndex >= 0
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			altitude: dockRoot.selectedDroneIndex >= 0 ? dockRoot.drones[dockRoot.selectedDroneIndex].altitude : 0
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
