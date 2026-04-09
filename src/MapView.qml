import QtLocation
import QtPositioning
import QtQuick
import QtQuick.Controls

Item {
	// MapLibre plugin with OpenFreeMap styles
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
		tilt: 45
		bearing: -17.6

		// Auto-select liberty style (index 1)
		Component.onCompleted: {
			if (supportedMapTypes.length > 1)
				activeMapType = supportedMapTypes[1];
		}

		// Style switcher overlay
		ComboBox {
			id: styleCombo
			z: 1
			anchors.top: parent.top
			anchors.right: parent.right
			anchors.margins: 8
			width: 220
			height: 40
			font.pixelSize: 14
			popup.width: 260
			popup.height: 250
			model: map.supportedMapTypes
			textRole: "name"
			currentIndex: 1
			onActivated: {
				map.activeMapType = map.supportedMapTypes[index];
			}
			background: Rectangle {
				radius: 4
				color: "#ccffffff"
				border.color: "#aaa"
				border.width: 1
			}
		}

		// Controls:
		//   Left drag          → pan (with inertia)
		//   Right drag         → rotate bearing
		//   Middle drag        → tilt (legacy)
		//   Mouse scroll       → zoom toward cursor
		//   Touchpad scroll    → pan (pixel-level smooth)
		//   Touchpad pinch     → zoom toward cursor (Ctrl+scroll)
		MouseArea {
			id: mouseArea
			anchors.fill: parent
			acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
			preventStealing: true

			property point lastPoint
			property real velocityX: 0
			property real velocityY: 0
			property bool inertiaActive: false

			onPressed: mouse => {
				lastPoint = Qt.point(mouse.x, mouse.y);
				velocityX = 0;
				velocityY = 0;
				inertiaActive = false;
				inertiaTimer.stop();
			}

			onPositionChanged: mouse => {
				var dx = mouse.x - lastPoint.x;
				var dy = mouse.y - lastPoint.y;

				if (mouse.buttons & Qt.LeftButton) {
					map.pan(-dx, -dy);
					// Exponential moving average for velocity tracking
					velocityX = velocityX * 0.6 + (-dx) * 0.4;
					velocityY = velocityY * 0.6 + (-dy) * 0.4;
				} else if (mouse.buttons & Qt.RightButton) {
					// Drag → rotate bearing
					map.bearing += dx * 0.3;
				} else if (mouse.buttons & Qt.MiddleButton) {
					// Vertical drag → tilt
					var newTilt2 = map.tilt + dy * 0.3;
					map.tilt = Math.max(0, Math.min(80, newTilt2));
				}

				lastPoint = Qt.point(mouse.x, mouse.y);
			}

			onReleased: mouse => {
				if (mouse.button === Qt.LeftButton) {
					if (Math.abs(velocityX) > 0.5 || Math.abs(velocityY) > 0.5) {
						inertiaActive = true;
						inertiaTimer.start();
					}
				}
			}

			// Kinetic (inertia) panning
			Timer {
				id: inertiaTimer
				interval: 16 // ~60fps
				repeat: true

				onTriggered: {
					if (!mouseArea.inertiaActive) {
						stop();
						return;
					}

					var friction = 0.92;
					mouseArea.velocityX *= friction;
					mouseArea.velocityY *= friction;

					if (Math.abs(mouseArea.velocityX) < 0.1 && Math.abs(mouseArea.velocityY) < 0.1) {
						mouseArea.inertiaActive = false;
						stop();
						return;
					}

					map.pan(mouseArea.velocityX, mouseArea.velocityY);
				}
			}

			// Debug: uncomment to see what your touchpad sends
			// onWheel: (wheel) => console.log("WHEEL pixelDelta=" + wheel.pixelDelta + " angleDelta=" + wheel.angleDelta + " mods=" + wheel.modifiers)

			onWheel: wheel => {
				// Ctrl + scroll → always zoom (explicit pinch shortcut)
				if (wheel.modifiers & Qt.ControlModifier) {
					var cz = (wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y) * 0.001;
					zoomTowardPoint(wheel.x, wheel.y, cz);
					return;
				}

				// Heuristic: real mouse wheel sends angleDelta in multiples of 120
				// Touchpad sends smooth, non-multiple-of-120 values (or only pixelDelta)
				var isDiscreteWheel = (wheel.angleDelta.y !== 0) && (wheel.angleDelta.y % 120 === 0) && (Math.abs(wheel.pixelDelta.y) < 1);

				if (isDiscreteWheel) {
					// Mouse wheel → zoom toward cursor
					var zoomDir = wheel.angleDelta.y > 0 ? 1 : -1;
					zoomTowardPoint(wheel.x, wheel.y, zoomDir * 0.3);
				} else {
					// Touchpad two-finger scroll → pan (browser-like)
					var dx = (wheel.pixelDelta.x !== 0) ? wheel.pixelDelta.x : wheel.angleDelta.x * 0.1;
					var dy = (wheel.pixelDelta.y !== 0) ? wheel.pixelDelta.y : wheel.angleDelta.y * 0.1;
					map.pan(-dx, -dy);
				}
			}
		}
	}

	// Zoom toward a specific screen point so the map zooms into
	// whatever is under the cursor.
	// Uses center adjustment in geographic space (not pan()) to avoid:
	//   - integer truncation causing drift over repeated zoom/unzoom
	//   - sign/coordinate issues with fromCoordinate under tilt/bearing
	function zoomTowardPoint(px, py, delta) {
		var currentZoom = map.zoomLevel;
		var newZoom = Math.max(map.minimumZoomLevel, Math.min(map.maximumZoomLevel, currentZoom + delta));
		if (newZoom === currentZoom)
			return;

		// Coordinate under cursor before zoom
		var targetCoord = map.toCoordinate(Qt.point(px, py), false);

		// Apply zoom
		map.zoomLevel = newZoom;

		// What coordinate is now under the cursor after zoom?
		var currentCoord = map.toCoordinate(Qt.point(px, py), false);

		// Shift center so targetCoord ends up back under the cursor
		map.center = QtPositioning.coordinate(map.center.latitude + targetCoord.latitude - currentCoord.latitude, map.center.longitude + targetCoord.longitude - currentCoord.longitude);
	}
}
