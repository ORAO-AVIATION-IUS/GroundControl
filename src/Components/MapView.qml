pragma ComponentBehavior: Bound

import MapLibre.Location
import QtLocation
import QtPositioning
import QtQuick

Item {
	id: root

	// ───── Public inputs (stateless) ─────
	// drones: array of { position: QGeoCoordinate, altitude: real (m AGL), heading: real (deg CW from north) }
	property var drones: []
	property var flightPaths: []                            // array<array<QGeoCoordinate>>

	// ───── View modes ─────
	property bool threeD: true
	property bool lightMode: true

	// Style index into supportedMapTypes (mirrors maplibre.map.styles order):
	// 0=bright, 1=liberty, 2=positron, 3=dark, 4=fiord, 5=night-3d (local)
	readonly property int _styleIndex: threeD ? (lightMode ? 1 : 5) : (lightMode ? 0 : 4)

	property real _savedTilt: 45

	onThreeDChanged: {
		if (threeD) {
			map.tilt = _savedTilt;
		} else {
			_savedTilt = map.tilt;
			map.tilt = 0;
		}
	}

	on_StyleIndexChanged: _applyStyle()
	function _applyStyle() {
		if (map.supportedMapTypes.length > _styleIndex)
			map.activeMapType = map.supportedMapTypes[_styleIndex];
	}

	// ───── Camera defaults (overridable) ─────
	property var initialCenter: QtPositioning.coordinate(41.0082, 28.9784)
	property real initialZoom: 15.5
	property real initialTilt: 45
	property real initialBearing: -17.6

	function _isValidDrone(d) {
		return d && d.position && d.position.isValid;
	}

	// ───── Pure geometry helpers (no state) ─────
	QtObject {
		id: geometry

		readonly property var _emptyFC: ({
				"type": "FeatureCollection",
				"features": []
			})

		function _offset(c, alongM, perpM, hdg) {
			const d = Math.sqrt(alongM * alongM + perpM * perpM);
			if (d === 0)
				return c;
			const a = Math.atan2(perpM, alongM) * 180 / Math.PI;
			return c.atDistanceAndAzimuth(d, hdg + a);
		}

		// Heading-rotated rectangle as a closed [lon,lat] ring.
		function _polyRect(c, halfA, halfP, hdg) {
			const p1 = _offset(c, halfA, halfP, hdg);
			const p2 = _offset(c, halfA, -halfP, hdg);
			const p3 = _offset(c, -halfA, -halfP, hdg);
			const p4 = _offset(c, -halfA, halfP, hdg);
			return [[p1.longitude, p1.latitude], [p2.longitude, p2.latitude], [p3.longitude, p3.latitude], [p4.longitude, p4.latitude], [p1.longitude, p1.latitude]];
		}

		function droneBodyGeoJson(drones) {
			const features = [];
			for (let i = 0; i < (drones || []).length; ++i) {
				const d = drones[i];
				if (!root._isValidDrone(d))
					continue;
				const c = d.position, hdg = d.heading || 0, alt = d.altitude || 0;
				const props = {
					"base": alt,
					"height": alt + 1.67
				};
				features.push({
					"type": "Feature",
					"properties": props,
					"geometry": {
						"type": "Polygon",
						"coordinates": [_polyRect(c, 6, 0.67, hdg)]
					}
				});
				features.push({
					"type": "Feature",
					"properties": props,
					"geometry": {
						"type": "Polygon",
						"coordinates": [_polyRect(c, 0.67, 6, hdg)]
					}
				});
				features.push({
					"type": "Feature",
					"properties": props,
					"geometry": {
						"type": "Polygon",
						"coordinates": [_polyRect(c, 2, 2, hdg)]
					}
				});
			}
			return {
				"type": "FeatureCollection",
				"features": features
			};
		}

		function rotorGeoJson(drones) {
			const features = [];
			for (let i = 0; i < (drones || []).length; ++i) {
				const d = drones[i];
				if (!root._isValidDrone(d))
					continue;
				const c = d.position, hdg = d.heading || 0, alt = d.altitude || 0;
				const props = {
					"base": alt + 1,
					"height": alt + 2.33
				};
				const ring = function (alongM, perpM) {
					return _polyRect(_offset(c, alongM, perpM, hdg), 1.33, 1.33, hdg);
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

		// Vertical dashed tethers from ground up to each drone's altitude.
		// 25 m pitch, 18 m segment. Each feature carries base/height for the layer.
		function tetherSegmentsGeoJson(drones) {
			const features = [];
			const pitch = 25, on = 18;
			for (let i = 0; i < (drones || []).length; ++i) {
				const d = drones[i];
				if (!root._isValidDrone(d) || (d.altitude || 0) <= 0)
					continue;
				const poly = _polyRect(d.position, 0.83, 0.83, 0);
				const altitude = d.altitude;
				for (let base = 0; base < altitude; base += pitch) {
					const top = Math.min(base + on, altitude);
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

		// Ground triangle marker, sized in meters but scaled inversely with
		// zoom so it stays roughly constant on screen.
		function gpsTrianglePath(c, hdg, zoomLevel) {
			if (!c || !c.isValid)
				return [];
			const size = 6 * Math.pow(2, 18 - zoomLevel);
			return [c.atDistanceAndAzimuth(size, hdg), c.atDistanceAndAzimuth(size * 0.8, hdg + 140), c.atDistanceAndAzimuth(size * 0.8, hdg - 140)];
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

		// 3D drone geometry bound to root inputs via pure helpers.
		MapLibre.style: Style {
			SourceParameter {
				styleId: "drone-body-source"
				type: "geojson"
				property var data: root.threeD ? geometry.droneBodyGeoJson(root.drones) : ({
						"type": "FeatureCollection",
						"features": []
					})
			}
			LayerParameter {
				styleId: "drone-body-layer"
				type: "fill-extrusion"
				property string source: "drone-body-source"
				// MapLibre converts QVariantMap to QJsonObject at runtime; qmllint cannot infer that.
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
				property var data: root.threeD ? geometry.rotorGeoJson(root.drones) : ({
						"type": "FeatureCollection",
						"features": []
					})
			}
			LayerParameter {
				styleId: "drone-rotor-layer"
				type: "fill-extrusion"
				property string source: "drone-rotor-source"
				// MapLibre converts QVariantMap to QJsonObject at runtime; qmllint cannot infer that.
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
				property var data: root.threeD ? geometry.tetherSegmentsGeoJson(root.drones) : ({
						"type": "FeatureCollection",
						"features": []
					})
			}
			LayerParameter {
				styleId: "tether-layer"
				type: "fill-extrusion"
				property string source: "tether-source"
				// MapLibre converts QVariantMap to QJsonObject at runtime; qmllint cannot infer that.
				// qmllint disable incompatible-type
				paint: ({
						"fill-extrusion-color": "#00d0ff",
						"fill-extrusion-base": ["get", "base"],
						"fill-extrusion-height": ["get", "height"],
						"fill-extrusion-opacity": 0.9
					})
			}
		}

		// Flight path trails — one polyline per entry in flightPaths.
		// Declared before the GPS markers so trails render beneath them.
		MapItemView {
			model: root.flightPaths
			delegate: MapPolyline {
				required property var modelData
				visible: modelData && modelData.length > 1
				line.width: 3
				line.color: "#ffaa00"
				path: modelData || []
			}
		}

		// Ground GPS markers — one per drone.
		MapItemView {
			model: root.drones
			delegate: MapPolygon {
				required property var modelData
				visible: root._isValidDrone(modelData)
				color: "#ff3030"
				border.color: "white"
				border.width: 3
				path: visible ? geometry.gpsTrianglePath(modelData.position, modelData.heading || 0, map.zoomLevel) : []
			}
		}

		// Controls:
		//   Left drag            -> pan (with inertia)
		//   Ctrl + Left drag     -> rotate / tilt (same as right drag)
		//   Right drag H         -> rotate bearing
		//   Right drag V         -> tilt
		//   Mouse wheel          -> zoom toward cursor
		//   Touchpad 2-finger V  -> zoom
		//   Touchpad 2-finger H  -> rotate bearing
		//   Ctrl + 2-finger V    -> tilt
		//   Ctrl + 2-finger H    -> rotate bearing
		MouseArea {
			id: mouseArea
			anchors.fill: parent
			acceptedButtons: Qt.LeftButton | Qt.RightButton
			preventStealing: true
			cursorShape: Qt.ArrowCursor

			property point lastPoint
			property real velocityX: 0
			property real velocityY: 0
			property bool inertiaActive: false

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

			function clampTilt(value) {
				return Math.max(kMinTilt, Math.min(kMaxTilt, value));
			}

			onPressed: function (mouse) {
				lastPoint = Qt.point(mouse.x, mouse.y);
				velocityX = 0;
				velocityY = 0;
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
				const dx = mouse.x - lastPoint.x;
				const dy = mouse.y - lastPoint.y;

				if (dragMode === modePan) {
					map.pan(-dx, -dy);
					velocityX = velocityX * 0.6 + (-dx) * 0.4;
					velocityY = velocityY * 0.6 + (-dy) * 0.4;
				} else if (dragMode === modeRotateTilt) {
					map.bearing += dx * kBearingSensitivity;
					if (root.threeD)
						map.tilt = clampTilt(map.tilt - dy * kTiltSensitivity);
				}

				lastPoint = Qt.point(mouse.x, mouse.y);
			}

			onReleased: function (mouse) {
				if (mouse.button === Qt.LeftButton && dragMode === modePan) {
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
				// Mouse wheel sends angleDelta in multiples of 120.
				// Touchpad sends smooth non-120 values or only pixelDelta.
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
	}

	// Zoom toward a screen point using geographic center adjustment
	// to avoid integer truncation drift from pan().
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
