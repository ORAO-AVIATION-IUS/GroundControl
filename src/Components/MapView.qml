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
	property int maxPathPoints: 5000

	property bool threeD: true
	property bool lightMode: true
	property bool satelliteMode: false

	readonly property int _styleIndex: threeD ? (lightMode ? 1 : 5) : (lightMode ? 0 : 4)
	property int _dataRevision: 0
	property real _savedTilt: 45
	property var _pathStore: ({})
	property var _trackedPaths: []
	property point _lastPointerPoint: Qt.point(0, 0)
	property bool _hasPointerOnMap: false
	property var hoveredCoordinate: QtPositioning.coordinate()

	property var initialCenter: QtPositioning.coordinate(41.0082, 28.9784)
	property real initialZoom: 15.5
	property real initialTilt: 45
	property real initialBearing: -17.6

	signal droneClicked(int droneUid)
	signal userMovedMap

	Component.onCompleted: scheduleDataRefresh()
	onDronesChanged: scheduleDataRefresh()
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
		return drone && (drone.latitude !== 0 || drone.longitude !== 0);
	}

	function scheduleDataRefresh() {
		dataRefreshTimer.restart();
	}

	function refreshTrackingData() {
		const paths = [];
		const activeKeys = {};

		for (let i = 0; i < (drones || []).length; ++i) {
			const drone = drones[i];
			if (!hasPosition(drone))
				continue;

			const key = String(drone.droneUid);
			activeKeys[key] = true;
			const coord = coordinateFor(drone);
			const oldPath = _pathStore[key] || [];

			if (oldPath.length === 0 || coord.distanceTo(oldPath[oldPath.length - 1]) >= 1.0) {
				let newPath = oldPath.concat([coord]);
				if (newPath.length > maxPathPoints)
					newPath = newPath.slice(newPath.length - maxPathPoints);
				_pathStore[key] = newPath;
			}
			paths.push(_pathStore[key]);
		}

		for (const key in _pathStore) {
			if (!activeKeys[key])
				delete _pathStore[key];
		}

		_trackedPaths = paths;
		_dataRevision += 1;
	}

	function droneUidAt(point) {
		const clickCoord = map.toCoordinate(point, false);
		if (!clickCoord.isValid)
			return -1;

		const onePixelCoord = map.toCoordinate(Qt.point(point.x + 1, point.y), false);
		const metersPerPixel = onePixelCoord.isValid ? clickCoord.distanceTo(onePixelCoord) : 1;
		const thresholdMeters = Math.max(8, metersPerPixel * 24);
		let bestUid = -1;
		let bestDistance = thresholdMeters;

		for (let i = 0; i < (drones || []).length; ++i) {
			const drone = drones[i];
			if (!hasPosition(drone))
				continue;
			const distance = clickCoord.distanceTo(coordinateFor(drone));
			if (distance <= bestDistance) {
				bestDistance = distance;
				bestUid = drone.droneUid;
			}
		}
		return bestUid;
	}

	function _applyStyle() {
		if (map.supportedMapTypes.length > _styleIndex)
			map.activeMapType = map.supportedMapTypes[_styleIndex];
	}

	function clearHoveredCoordinate() {
		_hasPointerOnMap = false;
		hoveredCoordinate = QtPositioning.coordinate();
	}

	function formatCoordinate(coordinate) {
		if (!coordinate || !coordinate.isValid)
			return "";
		return qsTr("%1, %2").arg(Number(coordinate.latitude).toFixed(6)).arg(Number(coordinate.longitude).toFixed(6));
	}

	function refreshHoveredCoordinate() {
		if (_hasPointerOnMap)
			updateHoveredCoordinate(_lastPointerPoint);
	}

	function updateHoveredCoordinate(point) {
		_lastPointerPoint = point;
		_hasPointerOnMap = true;

		const coordinate = map.toCoordinate(point, false);
		hoveredCoordinate = coordinate && coordinate.isValid ? coordinate : QtPositioning.coordinate();
	}

	onThreeDChanged: {
		if (threeD) {
			map.tilt = _savedTilt;
		} else {
			_savedTilt = map.tilt;
			map.tilt = 0;
		}
	}

	Timer {
		id: dataRefreshTimer
		interval: 50
		onTriggered: root.refreshTrackingData()
	}

	Repeater {
		model: root.drones
		delegate: Item {
			id: droneSignalDelegate

			required property var modelData

			Connections {
				target: droneSignalDelegate.modelData

				function onAltitudeChanged() {
					root.scheduleDataRefresh();
				}

				function onHeadingChanged() {
					root.scheduleDataRefresh();
				}

				function onLatitudeChanged() {
					root.scheduleDataRefresh();
				}

				function onLongitudeChanged() {
					root.scheduleDataRefresh();
				}
			}
		}
	}

	QtObject {
		id: geometry

		readonly property var emptyFeatureCollection: ({
				"type": "FeatureCollection",
				"features": []
			})

		function offset(c, alongM, perpM, hdg) {
			const d = Math.sqrt(alongM * alongM + perpM * perpM);
			if (d === 0)
				return c;
			const a = Math.atan2(perpM, alongM) * 180 / Math.PI;
			return c.atDistanceAndAzimuth(d, hdg + a);
		}

		function polyRect(c, halfA, halfP, hdg) {
			const p1 = offset(c, halfA, halfP, hdg);
			const p2 = offset(c, halfA, -halfP, hdg);
			const p3 = offset(c, -halfA, -halfP, hdg);
			const p4 = offset(c, -halfA, halfP, hdg);
			return [[p1.longitude, p1.latitude], [p2.longitude, p2.latitude], [p3.longitude, p3.latitude], [p4.longitude, p4.latitude], [p1.longitude, p1.latitude]];
		}

		function droneBodyGeoJson(drones, revision) {
			void revision;
			const features = [];
			for (let i = 0; i < (drones || []).length; ++i) {
				const drone = drones[i];
				if (!root.hasPosition(drone))
					continue;
				const c = root.coordinateFor(drone);
				const hdg = drone.heading || 0;
				const alt = drone.altitude || 0;
				const props = {
					"base": alt,
					"height": alt + 1.67
				};
				features.push({
					"type": "Feature",
					"properties": props,
					"geometry": {
						"type": "Polygon",
						"coordinates": [polyRect(c, 6, 0.67, hdg)]
					}
				});
				features.push({
					"type": "Feature",
					"properties": props,
					"geometry": {
						"type": "Polygon",
						"coordinates": [polyRect(c, 0.67, 6, hdg)]
					}
				});
				features.push({
					"type": "Feature",
					"properties": props,
					"geometry": {
						"type": "Polygon",
						"coordinates": [polyRect(c, 2, 2, hdg)]
					}
				});
			}
			return {
				"type": "FeatureCollection",
				"features": features
			};
		}

		function rotorGeoJson(drones, revision) {
			void revision;
			const features = [];
			for (let i = 0; i < (drones || []).length; ++i) {
				const drone = drones[i];
				if (!root.hasPosition(drone))
					continue;
				const c = root.coordinateFor(drone);
				const hdg = drone.heading || 0;
				const alt = drone.altitude || 0;
				const props = {
					"base": alt + 1,
					"height": alt + 2.33
				};
				const ring = function (alongM, perpM) {
					return polyRect(offset(c, alongM, perpM, hdg), 1.33, 1.33, hdg);
				};
				features.push({
					"type": "Feature",
					"properties": props,
					"geometry": {
						"type": "Polygon",
						"coordinates": [ring(7.33, 0)]
					}
				});
				features.push({
					"type": "Feature",
					"properties": props,
					"geometry": {
						"type": "Polygon",
						"coordinates": [ring(-7.33, 0)]
					}
				});
				features.push({
					"type": "Feature",
					"properties": props,
					"geometry": {
						"type": "Polygon",
						"coordinates": [ring(0, 7.33)]
					}
				});
				features.push({
					"type": "Feature",
					"properties": props,
					"geometry": {
						"type": "Polygon",
						"coordinates": [ring(0, -7.33)]
					}
				});
			}
			return {
				"type": "FeatureCollection",
				"features": features
			};
		}

		function tetherSegmentsGeoJson(drones, revision) {
			void revision;
			const features = [];
			const pitch = 25;
			const onLength = 18;
			for (let i = 0; i < (drones || []).length; ++i) {
				const drone = drones[i];
				if (!root.hasPosition(drone) || (drone.altitude || 0) <= 0)
					continue;
				const poly = polyRect(root.coordinateFor(drone), 0.83, 0.83, 0);
				const altitude = drone.altitude;
				for (let base = 0; base < altitude; base += pitch) {
					const top = Math.min(base + onLength, altitude);
					if (top - base < 2)
						break;
					features.push({
						"type": "Feature",
						"properties": {
							"base": base,
							"height": top
						},
						"geometry": {
							"type": "Polygon",
							"coordinates": [poly]
						}
					});
				}
			}
			return {
				"type": "FeatureCollection",
				"features": features
			};
		}

		function groundMarkerGeoJson(drones, selectedUid, revision) {
			void revision;
			const features = [];
			for (let i = 0; i < (drones || []).length; ++i) {
				const drone = drones[i];
				if (!root.hasPosition(drone))
					continue;
				const c = root.coordinateFor(drone);
				const hdg = drone.heading || 0;
				const selected = drone.droneUid === selectedUid;
				const z = map.zoomLevel;
				const scale = z > 15 ? Math.pow(2, (18 - z) * 0.7) : Math.pow(2, 17.1 - z);
				const tip = c.atDistanceAndAzimuth(6 * scale, hdg);
				const bl = c.atDistanceAndAzimuth(4.8 * scale, hdg + 140);
				const br = c.atDistanceAndAzimuth(4.8 * scale, hdg - 140);
				const ring = [[tip.longitude, tip.latitude], [bl.longitude, bl.latitude], [br.longitude, br.latitude], [tip.longitude, tip.latitude]];
				features.push({
					"type": "Feature",
					"properties": {
						"fill": selected ? "#ffaa00" : "#ff3030",
						"outlineWidth": Math.max(1, 3 / Math.sqrt(scale))
					},
					"geometry": {
						"type": "Polygon",
						"coordinates": [ring]
					}
				});
			}
			return {
				"type": "FeatureCollection",
				"features": features
			};
		}

		function flightPathGeoJson(paths) {
			const features = [];
			for (let i = 0; i < (paths || []).length; ++i) {
				const path = paths[i];
				if (!path || path.length < 2)
					continue;
				const coords = [];
				for (let j = 0; j < path.length; ++j)
					coords.push([path[j].longitude, path[j].latitude]);
				features.push({
					"type": "Feature",
					"geometry": {
						"type": "LineString",
						"coordinates": coords
					}
				});
			}
			return {
				"type": "FeatureCollection",
				"features": features
			};
		}
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
		onBearingChanged: root.refreshHoveredCoordinate()
		onCenterChanged: root.refreshHoveredCoordinate()
		onTiltChanged: root.refreshHoveredCoordinate()
		onZoomLevelChanged: root.refreshHoveredCoordinate()

		MapLibre.style: Style {
			SourceParameter {
				styleId: "satellite-source"
				type: "raster"
				property var tiles: ["https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}", "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"]
				property int tileSize: 256
				property int maxzoom: 19
			}
			LayerParameter {
				styleId: "satellite-layer"
				type: "raster"
				property string source: "satellite-source"
				// qmllint disable incompatible-type
				layout: ({
						"visibility": root.satelliteMode ? "visible" : "none"
					})
			}

			SourceParameter {
				styleId: "drone-body-source"
				type: "geojson"
				property var data: root.threeD ? geometry.droneBodyGeoJson(root.drones, root._dataRevision) : geometry.emptyFeatureCollection
			}
			LayerParameter {
				styleId: "drone-body-layer"
				type: "fill-extrusion"
				property string source: "drone-body-source"
				// qmllint disable incompatible-type
				paint: ({
						"fill-extrusion-color": "#2a2a2a",
						"fill-extrusion-base": ["get", "base"],
						"fill-extrusion-height": ["get", "height"],
						"fill-extrusion-opacity": 0.95
					})
			}

			SourceParameter {
				styleId: "drone-rotor-source"
				type: "geojson"
				property var data: root.threeD ? geometry.rotorGeoJson(root.drones, root._dataRevision) : geometry.emptyFeatureCollection
			}
			LayerParameter {
				styleId: "drone-rotor-layer"
				type: "fill-extrusion"
				property string source: "drone-rotor-source"
				// qmllint disable incompatible-type
				paint: ({
						"fill-extrusion-color": "#ff3030",
						"fill-extrusion-base": ["get", "base"],
						"fill-extrusion-height": ["get", "height"],
						"fill-extrusion-opacity": 0.95
					})
			}

			SourceParameter {
				styleId: "tether-source"
				type: "geojson"
				property var data: root.threeD ? geometry.tetherSegmentsGeoJson(root.drones, root._dataRevision) : geometry.emptyFeatureCollection
			}
			LayerParameter {
				styleId: "tether-layer"
				type: "fill-extrusion"
				property string source: "tether-source"
				// qmllint disable incompatible-type
				paint: ({
						"fill-extrusion-color": "#00d0ff",
						"fill-extrusion-base": ["get", "base"],
						"fill-extrusion-height": ["get", "height"],
						"fill-extrusion-opacity": 0.9
					})
			}

			SourceParameter {
				styleId: "ground-marker-source"
				type: "geojson"
				property var data: geometry.groundMarkerGeoJson(root.drones, root.selectedDroneUid, root._dataRevision)
			}
			LayerParameter {
				styleId: "ground-marker-layer"
				type: "fill"
				property string source: "ground-marker-source"
				// qmllint disable incompatible-type
				paint: ({
						"fill-color": ["get", "fill"],
						"fill-opacity": 0.9
					})
			}
			LayerParameter {
				styleId: "ground-marker-outline"
				type: "line"
				property string source: "ground-marker-source"
				// qmllint disable incompatible-type
				paint: ({
						"line-color": "#ffffff",
						"line-width": ["get", "outlineWidth"]
					})
			}

			SourceParameter {
				styleId: "flight-path-source"
				type: "geojson"
				property var data: geometry.flightPathGeoJson(root._trackedPaths)
			}
			LayerParameter {
				styleId: "flight-path-layer"
				type: "line"
				property string source: "flight-path-source"
				// qmllint disable incompatible-type
				paint: ({
						"line-color": "#ffaa00",
						"line-width": 3,
						"line-opacity": 0.85
					})
			}
		}

		MouseArea {
			id: mouseArea
			anchors.fill: parent
			acceptedButtons: Qt.LeftButton | Qt.RightButton
			hoverEnabled: true
			preventStealing: true
			cursorShape: Qt.ArrowCursor

			property point lastPoint
			property point pressPoint
			property real velocityX: 0
			property real velocityY: 0
			property bool inertiaActive: false
			property bool movedSincePress: false
			property bool movementNotified: false

			readonly property int modeNone: 0
			readonly property int modePan: 1
			readonly property int modeRotateTilt: 2
			property int dragMode: modeNone

			readonly property real kBearingSensitivity: 0.3
			readonly property real kTiltSensitivity: 0.3
			readonly property real kTouchpadTiltSensitivity: 0.2
			readonly property real kTouchpadZoomSensitivity: 0.003
			readonly property real kZoomStep: 0.3
			readonly property real kMinTilt: 0
			readonly property real kMaxTilt: 80
			readonly property real kInertiaThreshold: 0.5
			readonly property real kInertiaCutoff: 0.1
			readonly property real kFriction: 0.92
			readonly property int kInertiaInterval: 16
			readonly property real kClickMoveThreshold: 4

			property var anchorCoord

			function clampTilt(value) {
				return Math.max(kMinTilt, Math.min(kMaxTilt, value));
			}

			function noteMapMovement() {
				if (movementNotified)
					return;
				movementNotified = true;
				root.userMovedMap();
			}

			onPressed: function (mouse) {
				lastPoint = Qt.point(mouse.x, mouse.y);
				root.updateHoveredCoordinate(lastPoint);
				pressPoint = lastPoint;
				anchorCoord = map.toCoordinate(lastPoint, false);
				velocityX = 0;
				velocityY = 0;
				movedSincePress = false;
				movementNotified = false;
				inertiaActive = false;
				inertiaTimer.stop();

				if (dragMode !== modeNone)
					return;

				if (mouse.button === Qt.LeftButton && !(mouse.modifiers & Qt.ControlModifier)) {
					dragMode = modePan;
					cursorShape = Qt.OpenHandCursor;
				} else {
					dragMode = modeRotateTilt;
					cursorShape = Qt.ClosedHandCursor;
				}
			}

			onPositionChanged: function (mouse) {
				const point = Qt.point(mouse.x, mouse.y);
				root.updateHoveredCoordinate(point);
				const dx = point.x - lastPoint.x;
				const dy = point.y - lastPoint.y;
				const pressDx = point.x - pressPoint.x;
				const pressDy = point.y - pressPoint.y;

				if (Math.sqrt(pressDx * pressDx + pressDy * pressDy) > kClickMoveThreshold) {
					movedSincePress = true;
					noteMapMovement();
				}

				if (dragMode === modePan) {
					const cur = map.toCoordinate(point, false);
					if (cur.isValid && anchorCoord.isValid) {
						map.center = QtPositioning.coordinate(map.center.latitude + anchorCoord.latitude - cur.latitude, map.center.longitude + anchorCoord.longitude - cur.longitude);
					}
					velocityX = velocityX * 0.6 + (-dx) * 0.4;
					velocityY = velocityY * 0.6 + (-dy) * 0.4;
				} else if (dragMode === modeRotateTilt) {
					map.bearing += dx * kBearingSensitivity;
					if (root.threeD)
						map.tilt = clampTilt(map.tilt - dy * kTiltSensitivity);
				}

				lastPoint = point;
			}

			onReleased: function (mouse) {
				if (!movedSincePress && mouse.button === Qt.LeftButton) {
					const uid = root.droneUidAt(Qt.point(mouse.x, mouse.y));
					if (uid >= 0)
						root.droneClicked(uid);
				}

				if (movedSincePress && mouse.button === Qt.LeftButton && dragMode === modePan) {
					if (Math.abs(velocityX) > kInertiaThreshold || Math.abs(velocityY) > kInertiaThreshold) {
						inertiaActive = true;
						inertiaTimer.start();
					}
				}
				dragMode = modeNone;
				cursorShape = Qt.ArrowCursor;
			}

			onCanceled: function () {
				inertiaTimer.stop();
				inertiaActive = false;
				dragMode = modeNone;
				cursorShape = Qt.ArrowCursor;
			}

			onExited: root.clearHoveredCoordinate()

			Timer {
				id: inertiaTimer
				interval: mouseArea.kInertiaInterval
				repeat: true

				onTriggered: {
					if (!mouseArea.inertiaActive) {
						stop();
						return;
					}

					mouseArea.velocityX *= mouseArea.kFriction;
					mouseArea.velocityY *= mouseArea.kFriction;

					if (Math.abs(mouseArea.velocityX) < mouseArea.kInertiaCutoff && Math.abs(mouseArea.velocityY) < mouseArea.kInertiaCutoff) {
						mouseArea.inertiaActive = false;
						stop();
						return;
					}

					map.pan(mouseArea.velocityX, mouseArea.velocityY);
				}
			}

			onWheel: function (wheel) {
				root.updateHoveredCoordinate(Qt.point(wheel.x, wheel.y));
				root.userMovedMap();
				const isDiscreteWheel = (wheel.angleDelta.y !== 0) && (wheel.angleDelta.y % 120 === 0) && (Math.abs(wheel.pixelDelta.y) < 1);

				if (isDiscreteWheel) {
					const zoomDir = wheel.angleDelta.y > 0 ? 1 : -1;
					root.zoomTowardPoint(wheel.x, wheel.y, zoomDir * kZoomStep);
					return;
				}

				const dx = (wheel.pixelDelta.x !== 0) ? wheel.pixelDelta.x : wheel.angleDelta.x * 0.1;
				const dy = (wheel.pixelDelta.y !== 0) ? wheel.pixelDelta.y : wheel.angleDelta.y * 0.1;

				if (wheel.modifiers & Qt.ControlModifier) {
					if (Math.abs(dy) >= Math.abs(dx)) {
						if (root.threeD)
							map.tilt = clampTilt(map.tilt - dy * kTouchpadTiltSensitivity);
					} else {
						map.bearing += dx * kBearingSensitivity;
					}
				} else {
					if (Math.abs(dy) >= Math.abs(dx)) {
						root.zoomTowardPoint(wheel.x, wheel.y, dy * kTouchpadZoomSensitivity);
					} else {
						map.bearing += dx * kBearingSensitivity;
					}
				}
			}
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

	function zoomTowardPoint(px, py, delta) {
		const newZoom = Math.max(map.minimumZoomLevel, Math.min(map.maximumZoomLevel, map.zoomLevel + delta));
		if (newZoom === map.zoomLevel)
			return;

		const targetCoord = map.toCoordinate(Qt.point(px, py), false);
		map.zoomLevel = newZoom;
		const currentCoord = map.toCoordinate(Qt.point(px, py), false);

		map.center = QtPositioning.coordinate(map.center.latitude + targetCoord.latitude - currentCoord.latitude, map.center.longitude + targetCoord.longitude - currentCoord.longitude);
	}
}
