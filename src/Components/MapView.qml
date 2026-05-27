pragma ComponentBehavior: Bound

import Agc.Style as AgcStyle
import MapLibre.Location
import QtLocation
import QtPositioning
import QtQuick

Item {
	id: root

	property var drones: []
	property int selectedDroneUid: -1
	property int followedDroneUid: -1
	property int maxPathPoints: 5000

	property bool threeD: true
	property bool lightMode: true
	property bool satelliteMode: false
	property var hoveredCoordinate: QtPositioning.coordinate()

	readonly property int _styleIndex: threeD ? (lightMode ? 1 : 5) : (lightMode ? 0 : 4)
	property real _savedTilt: 45

	property var initialCenter: QtPositioning.coordinate(41.0082, 28.9784)
	property real initialZoom: 15.5
	property real initialTilt: 45
	property real initialBearing: -17.6

	signal droneClicked(int droneUid)
	signal userMovedMap

	on_StyleIndexChanged: _applyStyle()

	function centerOn(coordinate) {
		if (coordinate && coordinate.isValid)
			map.center = coordinate;
	}

	function coordinateFor(drone) {
		if (!drone)
			return QtPositioning.coordinate();
		return QtPositioning.coordinate(drone.latitude, drone.longitude);
	}

	function hasPosition(drone) {
		return geometry.hasPosition(drone);
	}

	function _applyStyle() {
		if (map.supportedMapTypes.length > _styleIndex)
			map.activeMapType = map.supportedMapTypes[_styleIndex];
	}

	function formatCoordinate(coordinate) {
		if (!coordinate || !coordinate.isValid)
			return "";
		return qsTr("%1, %2").arg(Number(coordinate.latitude).toFixed(6)).arg(Number(coordinate.longitude).toFixed(6));
	}

	onThreeDChanged: {
		if (threeD) {
			map.tilt = _savedTilt;
		} else {
			_savedTilt = map.tilt;
			map.tilt = 0;
		}
	}

	MapGeometry {
		id: geometry
	}

	MapDroneTracker {
		id: droneTracker
		drones: root.drones
		maxPathPoints: root.maxPathPoints
	}

	Plugin {
		id: mapPlugin
		name: "maplibre"

		PluginParameter {
			name: "maplibre.map.styles"
			value: "https://tiles.openfreemap.org/styles/bright," + "https://tiles.openfreemap.org/styles/liberty," + "https://tiles.openfreemap.org/styles/positron," + "https://tiles.openfreemap.org/styles/dark," + "https://tiles.openfreemap.org/styles/fiord," + "qrc:/resources/assets/night-3d-style.json"
		}
	}

	Map {
		id: map
		anchors.fill: parent

		plugin: mapPlugin

		center: root.initialCenter
		zoomLevel: root.initialZoom
		minimumZoomLevel: 0
		maximumZoomLevel: 20

		tilt: root.threeD ? root.initialTilt : 0
		bearing: root.initialBearing

		Component.onCompleted: {
			root._savedTilt = root.initialTilt;
			root._applyStyle();
		}
		onBearingChanged: interactionArea.refreshHoveredCoordinate()
		onCenterChanged: interactionArea.refreshHoveredCoordinate()
		onTiltChanged: interactionArea.refreshHoveredCoordinate()
		onZoomLevelChanged: interactionArea.refreshHoveredCoordinate()

		MapLibre.style: MapLibreMapStyle {
			drones: root.drones
			selectedDroneUid: root.selectedDroneUid
			threeD: root.threeD
			satelliteMode: root.satelliteMode
			trackedPaths: droneTracker.trackedPaths
			revision: droneTracker.revision
			zoomLevel: map.zoomLevel
		}

		MapInteractionArea {
			id: interactionArea
			targetMap: map
			drones: root.drones
			followedDroneUid: root.followedDroneUid
			threeD: root.threeD
			onDroneClicked: function (droneUid) {
				root.droneClicked(droneUid);
			}
			onHoveredCoordinateChanged: root.hoveredCoordinate = interactionArea.hoveredCoordinate
			onUserMovedMap: root.userMovedMap()
		}

		Text {
			id: coordinateReadout
			z: 10
			anchors.left: parent.left
			anchors.bottom: parent.bottom
			anchors.margins: AgcStyle.Style.overlayMargin
			color: "#d8dde6"
			font.family: "monospace"
			font.pixelSize: 11
			style: Text.Outline
			styleColor: "#99000000"
			text: root.formatCoordinate(root.hoveredCoordinate)
		}
	}
}
