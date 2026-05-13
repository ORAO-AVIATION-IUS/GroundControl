import QtLocation
import QtPositioning
import QtQuick
import QtQuick.Controls

Item {
	id: root

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

		// Default center: Istanbul
		center: QtPositioning.coordinate(41.0082, 28.9784)
		zoomLevel: 15.5
		minimumZoomLevel: 0
		maximumZoomLevel: 20

		// 3D perspective
		tilt: 0
		bearing: -17.6

		Component.onCompleted: {
			if (supportedMapTypes.length > 0)
				activeMapType = supportedMapTypes[0];
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
			// liberty
		else if (_isDark)
			idx = 4;
			// fiord
		else
			idx = 0; // bright

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
