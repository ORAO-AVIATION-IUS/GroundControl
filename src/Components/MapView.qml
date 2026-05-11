import QtLocation
import QtPositioning
import QtQuick
import MapLibre.Location

Item {
	id: root

	// ───── Public inputs (stateless DTO) ─────
	// The view draws nothing unless `dronePosition` is a valid coordinate.
	property var  dronePosition: QtPositioning.coordinate()  // invalid by default
	property real droneAltitude: 0                            // meters AGL
	property real droneHeading:  0                            // deg CW from north
	property var  flightPath:    []                           // array<QGeoCoordinate>

	// ───── Camera defaults (overridable) ─────
	property var  initialCenter: QtPositioning.coordinate(41.0082, 28.9784)
	property real initialZoom:   15.5
	property real initialTilt:   45
	property real initialBearing: -17.6

	readonly property bool _hasDrone: dronePosition && dronePosition.isValid

	// ───── Pure geometry helpers (no state) ─────
	QtObject {
		id: geometry

		readonly property var _emptyFC: ({ "type": "FeatureCollection", "features": [] })

		function _offset(c, alongM, perpM, hdg) {
			const d = Math.sqrt(alongM * alongM + perpM * perpM);
			if (d === 0)
				return c;
			const a = Math.atan2(perpM, alongM) * 180 / Math.PI;
			return c.atDistanceAndAzimuth(d, hdg + a);
		}

		// Heading-rotated rectangle as a closed [lon,lat] ring.
		function _polyRect(c, halfA, halfP, hdg) {
			const p1 = _offset(c,  halfA,  halfP, hdg);
			const p2 = _offset(c,  halfA, -halfP, hdg);
			const p3 = _offset(c, -halfA, -halfP, hdg);
			const p4 = _offset(c, -halfA,  halfP, hdg);
			return [
				[p1.longitude, p1.latitude],
				[p2.longitude, p2.latitude],
				[p3.longitude, p3.latitude],
				[p4.longitude, p4.latitude],
				[p1.longitude, p1.latitude]
			];
		}

		function droneBodyGeoJson(c, hdg) {
			if (!c || !c.isValid)
				return _emptyFC;
			return {
				"type": "FeatureCollection",
				"features": [
					{ "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [_polyRect(c, 6,    0.67, hdg)] } },
					{ "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [_polyRect(c, 0.67, 6,    hdg)] } },
					{ "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [_polyRect(c, 2,    2,    hdg)] } }
				]
			};
		}

		function rotorGeoJson(c, hdg) {
			if (!c || !c.isValid)
				return _emptyFC;
			function rotorRing(alongM, perpM) {
				return _polyRect(_offset(c, alongM, perpM, hdg), 1.33, 1.33, hdg);
			}
			return {
				"type": "FeatureCollection",
				"features": [
					{ "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [rotorRing( 7.33,  0)] } },
					{ "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [rotorRing(-7.33,  0)] } },
					{ "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [rotorRing(  0,  7.33)] } },
					{ "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [rotorRing(  0, -7.33)] } }
				]
			};
		}

		// Vertical dashed tether from ground up to `altitude`.
		// 25 m pitch, 18 m segment. Each feature carries base/height for the layer.
		function tetherSegmentsGeoJson(c, altitude) {
			if (!c || !c.isValid || altitude <= 0)
				return _emptyFC;
			const poly = _polyRect(c, 0.83, 0.83, 0);
			const features = [];
			const pitch = 25, on = 18;
			for (let base = 0; base < altitude; base += pitch) {
				const top = Math.min(base + on, altitude);
				if (top - base < 2)
					break;
				features.push({
					"type": "Feature",
					"properties": { "base": base, "height": top },
					"geometry": { "type": "Polygon", "coordinates": [poly] }
				});
			}
			return { "type": "FeatureCollection", "features": features };
		}

		// Ground triangle marker, sized in meters but scaled inversely with
		// zoom so it stays roughly constant on screen.
		function gpsTrianglePath(c, hdg, zoomLevel) {
			if (!c || !c.isValid)
				return [];
			const size = 6 * Math.pow(2, 18 - zoomLevel);
			return [
				c.atDistanceAndAzimuth(size,        hdg),
				c.atDistanceAndAzimuth(size * 0.8,  hdg + 140),
				c.atDistanceAndAzimuth(size * 0.8,  hdg - 140)
			];
		}
	}

	Plugin {
		id: mapPlugin
		name: "maplibre"

		PluginParameter {
			name: "maplibre.map.styles"
			value: "https://tiles.openfreemap.org/styles/bright,"
				 + "https://tiles.openfreemap.org/styles/liberty,"
				 + "https://tiles.openfreemap.org/styles/positron,"
				 + "https://tiles.openfreemap.org/styles/dark,"
				 + "https://tiles.openfreemap.org/styles/fiord"
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

		tilt: root.initialTilt
		bearing: root.initialBearing

		Component.onCompleted: {
			if (supportedMapTypes.length > 1)
				activeMapType = supportedMapTypes[1];
		}

		// 3D drone geometry bound to root inputs via pure helpers.
		MapLibre.style: Style {
			SourceParameter {
				styleId: "drone-body-source"
				type: "geojson"
				property var data: geometry.droneBodyGeoJson(root.dronePosition, root.droneHeading)
			}
			LayerParameter {
				styleId: "drone-body-layer"
				type: "fill-extrusion"
				property string source: "drone-body-source"
				paint: ({
					"fill-extrusion-color": "#2a2a2a",
					"fill-extrusion-base":   root.droneAltitude,
					"fill-extrusion-height": root.droneAltitude + 1.67,
					"fill-extrusion-opacity": 0.95
				})
			}

			SourceParameter {
				styleId: "drone-rotor-source"
				type: "geojson"
				property var data: geometry.rotorGeoJson(root.dronePosition, root.droneHeading)
			}
			LayerParameter {
				styleId: "drone-rotor-layer"
				type: "fill-extrusion"
				property string source: "drone-rotor-source"
				paint: ({
					"fill-extrusion-color": "#ff3030",
					"fill-extrusion-base":   root.droneAltitude + 1,
					"fill-extrusion-height": root.droneAltitude + 2.33,
					"fill-extrusion-opacity": 0.95
				})
			}

			SourceParameter {
				styleId: "tether-source"
				type: "geojson"
				property var data: geometry.tetherSegmentsGeoJson(root.dronePosition, root.droneAltitude)
			}
			LayerParameter {
				styleId: "tether-layer"
				type: "fill-extrusion"
				property string source: "tether-source"
				paint: ({
					"fill-extrusion-color": "#00d0ff",
					"fill-extrusion-base":   ["get", "base"],
					"fill-extrusion-height": ["get", "height"],
					"fill-extrusion-opacity": 0.9
				})
			}
		}
		}

		// Ground GPS marker — only drawn when drone data is provided.
		MapPolygon {
			visible: root._hasDrone
			color: "#ff3030"
			border.color: "white"
			border.width: 3
			path: geometry.gpsTrianglePath(root.dronePosition, root.droneHeading, map.zoomLevel)
		}

		// Flight path trail — only drawn when caller provides it.
		MapPolyline {
			visible: root.flightPath && root.flightPath.length > 1
			line.width: 3
			line.color: "#ffaa00"
			path: root.flightPath
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

					if (Math.abs(mouseArea.velocityX) < mouseArea.kInertiaCutoff
							&& Math.abs(mouseArea.velocityY) < mouseArea.kInertiaCutoff) {
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
				const isDiscreteWheel = (wheel.angleDelta.y !== 0)
						&& (wheel.angleDelta.y % 120 === 0)
						&& (Math.abs(wheel.pixelDelta.y) < 1);

				if (isDiscreteWheel) {
					const zoomDir = wheel.angleDelta.y > 0 ? 1 : -1;
					root.zoomTowardPoint(wheel.x, wheel.y, zoomDir * kZoomStep);
					return;
				}

				const dx = (wheel.pixelDelta.x !== 0) ? wheel.pixelDelta.x : wheel.angleDelta.x * 0.1;
				const dy = (wheel.pixelDelta.y !== 0) ? wheel.pixelDelta.y : wheel.angleDelta.y * 0.1;

				if (wheel.modifiers & Qt.ControlModifier) {
					if (Math.abs(dy) >= Math.abs(dx)) {
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
		const newZoom = Math.max(map.minimumZoomLevel,
								 Math.min(map.maximumZoomLevel, map.zoomLevel + delta));
		if (newZoom === map.zoomLevel)
			return;

		const targetCoord = map.toCoordinate(Qt.point(px, py), false);
		map.zoomLevel = newZoom;
		const currentCoord = map.toCoordinate(Qt.point(px, py), false);

		map.center = QtPositioning.coordinate(
			map.center.latitude  + targetCoord.latitude  - currentCoord.latitude,
			map.center.longitude + targetCoord.longitude - currentCoord.longitude);
	}
}
