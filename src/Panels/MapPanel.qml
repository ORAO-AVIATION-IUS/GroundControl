pragma ComponentBehavior: Bound

import Agc.Components
import Agc.Mavlink
import Agc.Style
import QtQuick
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: dockRoot
	uniqueName: "mapPanel"
	title: qsTr("Map")

	property int mapMode: 0

	property var _targetStore: ({})
	property bool followSelectedDrone: false

	readonly property int selectedDroneIndex: SwarmManager.selectedDroneIndex
	readonly property var selectedDrone: SwarmManager.selectedDrone
	readonly property alias hoveredCoordinate: mapView.hoveredCoordinate

	onSelectedDroneChanged: {
		if (selectedDrone) {
			var entry = _targetStore[String(selectedDrone.droneUid)];
			if (entry && entry.locked)
				altTape.setTarget(entry.alt);
			else
				altTape.clearTarget();
		} else {
			altTape.clearTarget();
		}
	}

	function hasPosition(drone) {
		return drone && (drone.latitude !== 0 || drone.longitude !== 0);
	}

	function followSelected() {
		if (!selectedDrone || !hasPosition(selectedDrone))
			return;
		mapView.centerOn(mapView.coordinateFor(selectedDrone));
	}

	function selectDroneByUid(uid) {
		for (let i = 0; i < SwarmManager.droneList.length; ++i) {
			if (SwarmManager.droneList[i].droneUid === uid) {
				SwarmManager.selectDrone(i);
				return;
			}
		}
	}

	Item {
		anchors.fill: parent

		Repeater {
			model: SwarmManager.droneList
			delegate: Item {
				id: followDelegate

				required property var modelData

				Connections {
					target: followDelegate.modelData

					function onLatitudeChanged() {
						if (dockRoot.followSelectedDrone && followDelegate.modelData === dockRoot.selectedDrone)
							dockRoot.followSelected();
					}

					function onLongitudeChanged() {
						if (dockRoot.followSelectedDrone && followDelegate.modelData === dockRoot.selectedDrone)
							dockRoot.followSelected();
					}
				}
			}
		}

		MapView {
			id: mapView
			anchors.fill: parent

			threeD: mapSettings.is3d
			lightMode: !mapSettings.isDark
			satelliteMode: mapSettings.isSatellite
			drones: SwarmManager.droneList
			selectedDroneUid: dockRoot.selectedDrone ? dockRoot.selectedDrone.droneUid : -1
			onDroneClicked: function (droneUid) {
				dockRoot.selectDroneByUid(droneUid);
			}
			onUserMovedMap: dockRoot.followSelectedDrone = false
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
					checkable: true
					checked: dockRoot.followSelectedDrone
					enabled: dockRoot.selectedDrone && dockRoot.hasPosition(dockRoot.selectedDrone)
					onClicked: {
						dockRoot.followSelectedDrone = checked;
						if (checked)
							dockRoot.followSelected();
					}
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
					model: SwarmManager.droneList
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
					property bool _armed: dockRoot.selectedDrone ? dockRoot.selectedDrone.armed : false
					property bool _connected: dockRoot.selectedDrone ? dockRoot.selectedDrone.connected : false
					iconName: _armed ? "security-high" : "security-low"
					label: _armed ? "Disarm" : "Arm"
					labelColor: _armed ? "#ff6b6b" : "#6bffb8"
					highlighted: _armed
					enabled: _connected && (!_armed || !(dockRoot.selectedDrone && dockRoot.selectedDrone.inFlight))
					onClicked: if (dockRoot.selectedDrone)
						dockRoot.selectedDrone.armed ? dockRoot.selectedDrone.disarm() : dockRoot.selectedDrone.arm()
				}
				IconButton {
					iconName: "arrow-up-double"
					label: "Takeoff"
					labelColor: "#6bffb8"
					enabled: dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.selectedDrone.armed && !dockRoot.selectedDrone.inFlight
					onClicked: if (dockRoot.selectedDrone)
						dockRoot.selectedDrone.takeoff()
				}
				IconButton {
					iconName: "arrow-down-double"
					label: "Land"
					labelColor: "#ffd06b"
					enabled: dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.selectedDrone.inFlight
					onClicked: if (dockRoot.selectedDrone)
						dockRoot.selectedDrone.land()
				}
				IconButton {
					iconName: "go-home-large"
					label: "RTH"
					labelColor: "#6bb8ff"
					enabled: dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.selectedDrone.inFlight
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
				if (dockRoot.selectedDrone) {
					dockRoot._targetStore[String(dockRoot.selectedDrone.droneUid)] = {
						"alt": target,
						"locked": true
					};
					dockRoot.selectedDrone.setAltitude(target);
				}
			}
			onTargetReset: {
				if (dockRoot.selectedDrone)
					dockRoot._targetStore[String(dockRoot.selectedDrone.droneUid)] = {
						"alt": 0,
						"locked": false
					};
			}
		}
	}
}
