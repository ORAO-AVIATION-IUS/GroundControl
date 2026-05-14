import MapLibre 3.0
import QtLocation
import QtPositioning
import QtQuick
import QtQuick.Controls

Item {
	id: root

	// ───── DRONE TELEMETRY INTERFACE (wired to droneManager) ─────
	QtObject {
		id: drone
		objectName: "drone"

		// Inputs (writable)
		property var position: QtPositioning.coordinate(41.0082, 28.9784)
		property real altitude: 100 // meters AGL
		property real heading: 0 // deg CW from north

		// Path (auto-managed)
		property var path: []
		property real pathMinSpacingMeters: 1.0

		// API
		function resetPath() {
			path = [];
		}

		function pushTelemetry(lat, lon, alt, hdg) {
			altitude = alt;
			heading = hdg;
			position = QtPositioning.coordinate(lat, lon); // last → triggers path append
		}

		// Internal helpers

		// Returns a coordinate offset from `c` by `alongM` meters in the heading
		// direction and `perpM` meters perpendicular (right of heading).
		function _offset(c, alongM, perpM, hdg) {
			var d = Math.sqrt(alongM * alongM + perpM * perpM);
			if (d === 0)
				return c;
			var a = Math.atan2(perpM, alongM) * 180 / Math.PI;
			return c.atDistanceAndAzimuth(d, hdg + a);
		}

		// Heading-rotated rectangle (closed ring) at center `c`, half-extents
		// `halfA` (along heading) and `halfP` (perpendicular). Returns an array
		// of [lon, lat] pairs suitable for a GeoJSON Polygon ring.
		function _polyRect(c, halfA, halfP, hdg) {
			var p1 = _offset(c, halfA, halfP, hdg);
			var p2 = _offset(c, halfA, -halfP, hdg);
			var p3 = _offset(c, -halfA, -halfP, hdg);
			var p4 = _offset(c, -halfA, halfP, hdg);
			return [[p1.longitude, p1.latitude], [p2.longitude, p2.latitude], [p3.longitude, p3.latitude], [p4.longitude, p4.latitude], [p1.longitude, p1.latitude]];
		}

		// X-shape body: forward arm + lateral arm + central block.
		function droneBodyGeoJson() {
			var c = position;
			var h = heading;
			var fwdArm = _polyRect(c, 18, 2, h);
			var latArm = _polyRect(c, 2, 18, h);
			var body = _polyRect(c, 6, 6, h);
			return {
				"type": "FeatureCollection",
				"features": [
					{
						"type": "Feature",
						"geometry": {
							"type": "Polygon",
							"coordinates": [fwdArm]
						}
					},
					{
						"type": "Feature",
						"geometry": {
							"type": "Polygon",
							"coordinates": [latArm]
						}
					},
					{
						"type": "Feature",
						"geometry": {
							"type": "Polygon",
							"coordinates": [body]
						}
					}
				]
			};
		}

		// 4 rotors at the arm tips.
		function rotorGeoJson() {
			var c = position;
			var h = heading;
			function rotorRing(alongM, perpM) {
				var rc = _offset(c, alongM, perpM, h);
				return _polyRect(rc, 4, 4, h);
			}
			return {
				"type": "FeatureCollection",
				"features": [
					{
						"type": "Feature",
						"geometry": {
							"type": "Polygon",
							"coordinates": [rotorRing(22, 0)]
						}
					},
					{
						"type": "Feature",
						"geometry": {
							"type": "Polygon",
							"coordinates": [rotorRing(-22, 0)]
						}
					},
					{
						"type": "Feature",
						"geometry": {
							"type": "Polygon",
							"coordinates": [rotorRing(0, 22)]
						}
					},
					{
						"type": "Feature",
						"geometry": {
							"type": "Polygon",
							"coordinates": [rotorRing(0, -22)]
						}
					}
				]
			};
		}

		// Vertical dashed tether from ground (0) up to current altitude.
		// 25 m pitch, 18 m on / 7 m gap. Each feature carries `base`/`height`
		// properties consumed by the layer via ["get", …] expressions.
		function tetherSegmentsGeoJson() {
			var c = position;
			var poly = _polyRect(c, 2.5, 2.5, 0); // 5×5 m column
			var features = [];
			var pitch = 25, on = 18;
			for (var base = 0; base < altitude; base += pitch) {
				var top = Math.min(base + on, altitude);
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
			return {
				"type": "FeatureCollection",
				"features": features
			};
		}

		// 3-vertex ground triangle marker at the drone's lat/lon, sized in
		// meters but scaled inversely with zoom so it stays a roughly constant
		// pixel size on screen.
		function gpsTrianglePath() {
			var c = position;
			var h = heading;
			var size = 18 * Math.pow(2, 18 - map.zoomLevel);
			return [c.atDistanceAndAzimuth(size, h), c.atDistanceAndAzimuth(size * 0.8, h + 140), c.atDistanceAndAzimuth(size * 0.8, h - 140)];
		}
	}

	// Auto-append the flight path whenever the drone moves.
	Connections {
		target: drone
		function onPositionChanged() {
			var p = drone.path;
			if (p.length === 0 || drone.position.distanceTo(p[p.length - 1]) >= drone.pathMinSpacingMeters) {
				drone.path = p.concat([drone.position]);
			}
		}
	}

	// Wire drone telemetry to droneManager
	Connections {
		target: droneManager
		function onPositionChanged() {
			if (droneManager.connected)
				drone.position = QtPositioning.coordinate(droneManager.latitude, droneManager.longitude);
		}
		function onConnectedChanged() {
			if (!droneManager.connected) {
				drone.resetPath();
				drone.position = QtPositioning.coordinate(41.0082, 28.9784);
			}
		}
		function onAltitudeChanged() {
			drone.altitude = droneManager.altitude;
		}
		function onHeadingChanged() {
			drone.heading = droneManager.heading;
		}
	}

	Plugin {
		id: mapPlugin
		name: "maplibre"

		PluginParameter {
			name: "maplibre.map.styles"
			value: "https://tiles.openfreemap.org/styles/bright," + "https://tiles.openfreemap.org/styles/liberty," + "https://tiles.openfreemap.org/styles/positron," + "https://tiles.openfreemap.org/styles/dark," + "https://tiles.openfreemap.org/styles/fiord"
		}
	}

	Map {
		id: map
		anchors.fill: parent

		plugin: mapPlugin

		center: QtPositioning.coordinate(41.0082, 28.9784)
		zoomLevel: 15.5
		minimumZoomLevel: 0
		maximumZoomLevel: 20

		tilt: 0
		bearing: -17.6

		Component.onCompleted: {
			if (supportedMapTypes.length > 0)
				activeMapType = supportedMapTypes[0];
		}

		// MapLibre fill-extrusion layers — all geometry/altitude bound to `drone`.
		MapLibre.style: Style {
			// Drone X-shape body.
			SourceParameter {
				styleId: "drone-body-source"
				type: "geojson"
				property var data: drone.droneBodyGeoJson()
			}
			LayerParameter {
				styleId: "drone-body-layer"
				type: "fill-extrusion"
				property string source: "drone-body-source"
				paint: ({
						"fill-extrusion-color": "#2a2a2a",
						"fill-extrusion-base": drone.altitude,
						"fill-extrusion-height": drone.altitude + 5,
						"fill-extrusion-opacity": 0.95
					})
			}

			// Rotors at the arm tips.
			SourceParameter {
				styleId: "drone-rotor-source"
				type: "geojson"
				property var data: drone.rotorGeoJson()
			}
			LayerParameter {
				styleId: "drone-rotor-layer"
				type: "fill-extrusion"
				property string source: "drone-rotor-source"
				paint: ({
						"fill-extrusion-color": "#ff3030",
						"fill-extrusion-base": drone.altitude + 3,
						"fill-extrusion-height": drone.altitude + 7,
						"fill-extrusion-opacity": 0.95
					})
			}

			// Altitude tether — variable-count dashes via data-driven expressions.
			SourceParameter {
				styleId: "tether-source"
				type: "geojson"
				property var data: drone.tetherSegmentsGeoJson()
			}
			LayerParameter {
				styleId: "tether-layer"
				type: "fill-extrusion"
				property string source: "tether-source"
				paint: ({
						"fill-extrusion-color": "#00d0ff",
						"fill-extrusion-base": ["get", "base"],
						"fill-extrusion-height": ["get", "height"],
						"fill-extrusion-opacity": 0.9
					})
			}
		}

		// On-ground GPS marker triangle (zoom-scaled, oriented by heading).
		MapPolygon {
			color: "#ff3030"
			border.color: "white"
			border.width: 3
			path: drone.gpsTrianglePath()
		}

		// Flight path trail — grows automatically as the drone moves.
		MapPolyline {
			line.width: 3
			line.color: "#ffaa00"
			path: drone.path
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

			// State
			property point lastPoint
			property real velocityX: 0
			property real velocityY: 0
			property bool inertiaActive: false

			// Drag mode enum
			readonly property int modeNone: 0
			readonly property int modePan: 1
			readonly property int modeRotateTilt: 2
			property int dragMode: modeNone

			// Sensitivities / tunables
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

				if (dragMode === modeNone) {
					if (mouse.button === Qt.LeftButton && !(mouse.modifiers & Qt.ControlModifier)) {
						dragMode = modePan;
						cursorShape = Qt.OpenHandCursor;
					} else {
						dragMode = modeRotateTilt;
						cursorShape = Qt.ClosedHandCursor;
					}
				}
			}

			onPositionChanged: function (mouse) {
				let dx = mouse.x - lastPoint.x;
				let dy = mouse.y - lastPoint.y;

				if (mouseArea.dragMode === modePan) {
					map.pan(-dx, -dy);
					velocityX = velocityX * 0.6 + (-dx) * 0.4;
					velocityY = velocityY * 0.6 + (-dy) * 0.4;
				} else if (mouseArea.dragMode === modeRotateTilt) {
					map.bearing += dx * kBearingSensitivity;
					map.tilt = clampTilt(map.tilt - dy * kTiltSensitivity);
				}

				lastPoint = Qt.point(mouse.x, mouse.y);
			}

			onReleased: function (mouse) {
				if (mouse.button === Qt.LeftButton && mouseArea.dragMode === modePan) {
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
				let isDiscreteWheel = (wheel.angleDelta.y !== 0) && (wheel.angleDelta.y % 120 === 0) && (Math.abs(wheel.pixelDelta.y) < 1);

				if (isDiscreteWheel) {
					// Mouse wheel -> zoom toward cursor
					let zoomDir = wheel.angleDelta.y > 0 ? 1 : -1;
					root.zoomTowardPoint(wheel.x, wheel.y, zoomDir * kZoomStep);
				} else {
					// Touchpad scroll
					let dx = (wheel.pixelDelta.x !== 0) ? wheel.pixelDelta.x : wheel.angleDelta.x * 0.1;
					let dy = (wheel.pixelDelta.y !== 0) ? wheel.pixelDelta.y : wheel.angleDelta.y * 0.1;

					if (wheel.modifiers & Qt.ControlModifier) {
						// Ctrl + touchpad: vertical -> tilt, horizontal -> rotate
						if (Math.abs(dy) >= Math.abs(dx)) {
							map.tilt = clampTilt(map.tilt - dy * kTouchpadTiltSensitivity);
						} else {
							map.bearing += dx * kBearingSensitivity;
						}
					} else {
						// No Ctrl touchpad: vertical -> zoom, horizontal -> rotate
						if (Math.abs(dy) >= Math.abs(dx)) {
							let zoomDelta = dy * kTouchpadZoomSensitivity;
							root.zoomTowardPoint(wheel.x, wheel.y, zoomDelta);
						} else {
							map.bearing += dx * kBearingSensitivity;
						}
					}
				}
			}
		}
	}

	// Style indices: bright=0, liberty=1, positron=2, dark=3, fiord=4
	// 2D+light=bright(0), 2D+dark=fiord(4), 3D=liberty(1)
	property bool _is3d: false
	property bool _isDark: false

	function _updateStyle() {
		var idx = 0;
		if (_is3d)
			idx = 1;
		else if (_isDark)
			idx = 4;
		else
			idx = 0;

		if (idx < map.supportedMapTypes.length)
			map.activeMapType = map.supportedMapTypes[idx];
	}

	function setPerspective(enabled3d) {
		_is3d = enabled3d;
		map.tilt = enabled3d ? 45 : 0;
		_updateStyle();
	}

	function setTheme(isDark) {
		_isDark = isDark;
		_updateStyle();
	}

	// Zoom toward a screen point using geographic center adjustment
	// to avoid integer truncation drift from pan().
	function zoomTowardPoint(px, py, delta) {
		let newZoom = Math.max(map.minimumZoomLevel, Math.min(map.maximumZoomLevel, map.zoomLevel + delta));
		if (newZoom === map.zoomLevel)
			return;

		let targetCoord = map.toCoordinate(Qt.point(px, py), false);

		map.zoomLevel = newZoom;

		let currentCoord = map.toCoordinate(Qt.point(px, py), false);

		map.center = QtPositioning.coordinate(map.center.latitude + targetCoord.latitude - currentCoord.latitude, map.center.longitude + targetCoord.longitude - currentCoord.longitude);
	}
}
