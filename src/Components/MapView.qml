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
	property int mapMode: 0
	property string activePlanningTool: "edit"
	property string activeTrackingTool: ""
	property var missionItems: []
	property var visibleMissionPlans: []
	property var mapTargets: []
	property int selectedMissionItemIndex: -1
	property int currentMissionItemIndex: 0
	property double homeLatitude: 0
	property double homeLongitude: 0
	property bool homeValid: false
	property bool returnHomeAfterMission: false
	property bool goTargetValid: false
	property double goTargetLatitude: 0
	property double goTargetLongitude: 0
	property double goTargetAltitude: 0
	property double goTargetHeading: 0
	property bool lookTargetValid: false
	property double lookTargetLatitude: 0
	property double lookTargetLongitude: 0
	property double lookTargetHeading: 0
	property double flyTargetDroneLatitude: 0
	property double flyTargetDroneLongitude: 0
	property int missionRevision: 0

	readonly property int _styleIndex: threeD ? (lightMode ? 1 : 5) : (lightMode ? 0 : 4)
	property real _savedTilt: 45

	property var initialCenter: QtPositioning.coordinate(41.0082, 28.9784)
	property real initialZoom: 15.5
	property real initialTilt: 45
	property real initialBearing: -17.6

	signal droneClicked(int droneUid)
	signal missionMapClicked(var coordinate)
	signal homeMapClicked(var coordinate)
	signal mapContextRequested(var coordinate, point screenPoint)
	signal mapInteractionStarted
	signal flyTargetClicked(string targetKind)
	signal flyTargetEditStarted(string targetKind)
	signal flyTargetMoved(string targetKind, var coordinate)
	signal missionItemClicked(int index)
	signal missionPlanItemClicked(int droneUid, int index)
	signal missionItemMoved(int index, var coordinate)
	signal missionSegmentInsertRequested(int segmentIndex, var coordinate)
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
			mapMode: root.mapMode
			threeD: root.threeD
			satelliteMode: root.satelliteMode
			trackedPaths: droneTracker.trackedPaths
			missionItems: root.missionItems
			visibleMissionPlans: root.visibleMissionPlans
			mapTargets: root.mapTargets
			selectedMissionItemIndex: root.selectedMissionItemIndex
			currentMissionItemIndex: root.currentMissionItemIndex
			homeLatitude: root.homeLatitude
			homeLongitude: root.homeLongitude
			homeValid: root.homeValid
			returnHomeAfterMission: root.returnHomeAfterMission
			goTargetValid: root.goTargetValid
			goTargetLatitude: root.goTargetLatitude
			goTargetLongitude: root.goTargetLongitude
			goTargetAltitude: root.goTargetAltitude
			goTargetHeading: root.goTargetHeading
			lookTargetValid: root.lookTargetValid
			lookTargetLatitude: root.lookTargetLatitude
			lookTargetLongitude: root.lookTargetLongitude
			lookTargetHeading: root.lookTargetHeading
			flyTargetDroneLatitude: root.flyTargetDroneLatitude
			flyTargetDroneLongitude: root.flyTargetDroneLongitude
			showMissionInsertHandles: root.mapMode === 1
			revision: droneTracker.revision
			missionRevision: root.missionRevision
			zoomLevel: map.zoomLevel
		}

		MapInteractionArea {
			id: interactionArea
			targetMap: map
			drones: root.drones
			followedDroneUid: root.followedDroneUid
			selectedDroneUid: root.selectedDroneUid
			threeD: root.threeD
			mapMode: root.mapMode
			activePlanningTool: root.activePlanningTool
			activeTrackingTool: root.activeTrackingTool
			missionItems: root.missionItems
			visibleMissionPlans: root.visibleMissionPlans
			mapTargets: root.mapTargets
			homeLatitude: root.homeLatitude
			homeLongitude: root.homeLongitude
			homeValid: root.homeValid
			goTargetValid: root.goTargetValid
			goTargetLatitude: root.goTargetLatitude
			goTargetLongitude: root.goTargetLongitude
			lookTargetValid: root.lookTargetValid
			lookTargetLatitude: root.lookTargetLatitude
			lookTargetLongitude: root.lookTargetLongitude
			onDroneClicked: function (droneUid) {
				root.droneClicked(droneUid);
			}
			onMissionMapClicked: function (coordinate) {
				root.missionMapClicked(coordinate);
			}
			onHomeMapClicked: function (coordinate) {
				root.homeMapClicked(coordinate);
			}
			onMapContextRequested: function (coordinate, screenPoint) {
				root.mapContextRequested(coordinate, screenPoint);
			}
			onMapInteractionStarted: root.mapInteractionStarted()
			onFlyTargetClicked: function (targetKind) {
				root.flyTargetClicked(targetKind);
			}
			onFlyTargetEditStarted: function (targetKind) {
				root.flyTargetEditStarted(targetKind);
			}
			onFlyTargetMoved: function (targetKind, coordinate) {
				root.flyTargetMoved(targetKind, coordinate);
			}
			onMissionItemClicked: function (index) {
				root.missionItemClicked(index);
			}
			onMissionPlanItemClicked: function (droneUid, index) {
				root.missionPlanItemClicked(droneUid, index);
			}
			onMissionItemMoved: function (index, coordinate) {
				root.missionItemMoved(index, coordinate);
			}
			onMissionSegmentInsertRequested: function (segmentIndex, coordinate) {
				root.missionSegmentInsertRequested(segmentIndex, coordinate);
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
