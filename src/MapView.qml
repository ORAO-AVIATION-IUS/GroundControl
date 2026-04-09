import QtLocation
import QtPositioning
import QtQuick
import QtQuick.Controls

Item {
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
			onActivated: function (index) {
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
		//   Left drag            -> pan (with inertia)
		//   Right drag H         -> rotate bearing
		//   Right drag V         -> tilt
		//   Mouse wheel          -> zoom toward cursor
		//   Touchpad 2-finger H  -> rotate bearing
		//   Touchpad 2-finger V  -> tilt
		//   Ctrl + scroll        -> zoom toward cursor
		MouseArea {
			id: mouseArea
			anchors.fill: parent
			acceptedButtons: Qt.LeftButton | Qt.RightButton
			preventStealing: true

			property point lastPoint
			property real velocityX: 0
			property real velocityY: 0
			property bool inertiaActive: false

			onPressed: function (mouse) {
				lastPoint = Qt.point(mouse.x, mouse.y);
				velocityX = 0;
				velocityY = 0;
				inertiaActive = false;
				inertiaTimer.stop();
			}

			onPositionChanged: function (mouse) {
				var dx = mouse.x - lastPoint.x;
				var dy = mouse.y - lastPoint.y;

				if (mouse.buttons & Qt.LeftButton) {
					map.pan(-dx, -dy);
					velocityX = velocityX * 0.6 + (-dx) * 0.4;
					velocityY = velocityY * 0.6 + (-dy) * 0.4;
				} else if (mouse.buttons & Qt.RightButton) {
					map.bearing += dx * 0.3;
					map.tilt = Math.max(0, Math.min(80, map.tilt - dy * 0.3));
				}

				lastPoint = Qt.point(mouse.x, mouse.y);
			}

			onReleased: function (mouse) {
				if (mouse.button === Qt.LeftButton) {
					if (Math.abs(velocityX) > 0.5 || Math.abs(velocityY) > 0.5) {
						inertiaActive = true;
						inertiaTimer.start();
					}
				}
			}

			Timer {
				id: inertiaTimer
				interval: 16
				repeat: true

				onTriggered: {
					if (!mouseArea.inertiaActive) {
						stop();
						return;
					}

					mouseArea.velocityX *= 0.92;
					mouseArea.velocityY *= 0.92;

					if (Math.abs(mouseArea.velocityX) < 0.1 && Math.abs(mouseArea.velocityY) < 0.1) {
						mouseArea.inertiaActive = false;
						stop();
						return;
					}

					map.pan(mouseArea.velocityX, mouseArea.velocityY);
				}
			}

			onWheel: function (wheel) {
				// Ctrl + scroll -> zoom toward cursor
				if (wheel.modifiers & Qt.ControlModifier) {
					var cz = (wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y) * 0.001;
					zoomTowardPoint(wheel.x, wheel.y, cz);
					return;
				}

				// Mouse wheel sends angleDelta in multiples of 120.
				// Touchpad sends smooth non-120 values or only pixelDelta.
				var isDiscreteWheel = (wheel.angleDelta.y !== 0) && (wheel.angleDelta.y % 120 === 0) && (Math.abs(wheel.pixelDelta.y) < 1);

				if (isDiscreteWheel) {
					// Mouse wheel -> zoom toward cursor
					var zoomDir = wheel.angleDelta.y > 0 ? 1 : -1;
					zoomTowardPoint(wheel.x, wheel.y, zoomDir * 0.3);
				} else {
					// Touchpad scroll
					var dx = (wheel.pixelDelta.x !== 0) ? wheel.pixelDelta.x : wheel.angleDelta.x * 0.1;
					var dy = (wheel.pixelDelta.y !== 0) ? wheel.pixelDelta.y : wheel.angleDelta.y * 0.1;

					if (Math.abs(dx) > Math.abs(dy)) {
						map.bearing += dx * 0.3;
					} else {
						map.tilt = Math.max(0, Math.min(80, map.tilt - dy * 0.2));
					}
				}
			}
		}
	}

	// Zoom toward a screen point using geographic center adjustment
	// to avoid integer truncation drift from pan().
	function zoomTowardPoint(px, py, delta) {
		var newZoom = Math.max(map.minimumZoomLevel, Math.min(map.maximumZoomLevel, map.zoomLevel + delta));
		if (newZoom === map.zoomLevel)
			return;

		var targetCoord = map.toCoordinate(Qt.point(px, py), false);

		map.zoomLevel = newZoom;

		var currentCoord = map.toCoordinate(Qt.point(px, py), false);

		map.center = QtPositioning.coordinate(map.center.latitude + targetCoord.latitude - currentCoord.latitude, map.center.longitude + targetCoord.longitude - currentCoord.longitude);
	}
}
