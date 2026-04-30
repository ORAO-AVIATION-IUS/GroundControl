import QtLocation
import QtPositioning
import QtQuick
import QtQuick.Controls
import "qrc:/src/components"
import "qrc:/src/theme"

Item {
	id: root

	property bool autoRotating: false

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
			visible: false
			z: mapOverlay.z + 1
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

	// Auto-rotation timer
	Timer {
		id: rotationTimer
		interval: 50
		repeat: true
		running: root.autoRotating
		onTriggered: map.bearing += 0.3
	}

	// ---- Button overlay on top of map ----
	// This Item sits above the Map's MouseArea so its children receive
	// pointer events first. Only the small button rectangles consume events;
	// everything else passes through to the map controls below.
	Item {
		id: mapOverlay
		z: 1
		anchors.fill: parent

		// Prevent the overlay item itself from stealing events.
		// Only the explicit MouseAreas inside buttons will consume clicks.
		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.NoButton
			hoverEnabled: false
		}

		// Map buttons — vertical toolbar on the left
		Column {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			anchors.margins: 6
			spacing: 6
			width: childrenRect.width

			// PATH section
			Rectangle {
				width: pathCol.implicitWidth + 20
				height: pathCol.implicitHeight + 20
				color: "#1c1f26"
				radius: 5

				Column {
					id: pathCol
					anchors.centerIn: parent
					spacing: 6

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: "PATH"
						color: "#6b7a8d"
						font.pixelSize: 7
						font.letterSpacing: 1
					}

					IconButton {
						iconName: "draw-freehand"
						label: "Draw"
						anchors.horizontalCenter: parent.horizontalCenter
						onClicked: console.log("Draw Path")
					}
					IconButton {
						iconName: "draw-eraser"
						label: "Erase"
						anchors.horizontalCenter: parent.horizontalCenter
						onClicked: console.log("Erase Path")
					}
					IconButton {
						iconName: "system-search"
						label: "Scan"
						anchors.horizontalCenter: parent.horizontalCenter
						onClicked: console.log("Scan Area")
					}
				}
			}

			// ZOOM section
			Rectangle {
				width: mapZoomCol.implicitWidth + 20
				height: mapZoomCol.implicitHeight + 20
				color: "#1c1f26"
				radius: 5

				Column {
					id: mapZoomCol
					anchors.centerIn: parent
					spacing: 6

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: "ZOOM"
						color: "#6b7a8d"
						font.pixelSize: 7
						font.letterSpacing: 1
					}

					IconButton {
						iconName: "zoom-in"
						label: "In"
						anchors.horizontalCenter: parent.horizontalCenter
						onClicked: zoomTowardPoint(map.width / 2, map.height / 2, 0.5)
					}
					IconButton {
						iconName: "zoom-out"
						label: "Out"
						anchors.horizontalCenter: parent.horizontalCenter
						onClicked: zoomTowardPoint(map.width / 2, map.height / 2, -0.5)
					}
				}
			}

			// ROTATE section
			Rectangle {
				width: rotateCol.implicitWidth + 20
				height: rotateCol.implicitHeight + 20
				color: root.autoRotating ? "#1a3a2a" : "#1c1f26"
				radius: 5
				border.color: root.autoRotating ? "#6bffb8" : "transparent"
				border.width: root.autoRotating ? 1 : 0

				Column {
					id: rotateCol
					anchors.centerIn: parent
					spacing: 6

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: "ROTATE"
						color: root.autoRotating ? "#6bffb8" : "#6b7a8d"
						font.pixelSize: 7
						font.letterSpacing: 1
					}

					IconButton {
						iconName: "media-playback-start"
						label: root.autoRotating ? "Stop" : "Spin"
						labelColor: root.autoRotating ? "#6bffb8" : "#ccc"
						anchors.horizontalCenter: parent.horizontalCenter
						onClicked: root.autoRotating = !root.autoRotating
					}
				}
			}
		}

		// Camera buttons — horizontal toolbar on the top-right
		Row {
			anchors.top: parent.top
			anchors.right: parent.right
			anchors.rightMargin: 6
			spacing: 6

			// ZOOM section
			Rectangle {
				height: camZoomCol.implicitHeight + 20
				width: camZoomRow.implicitWidth + 20
				color: "#1c1f26"
				radius: 5

				Column {
					id: camZoomCol
					anchors.centerIn: parent
					spacing: 3

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: "ZOOM"
						color: "#6b7a8d"
						font.pixelSize: 7
						font.letterSpacing: 1
					}

					Row {
						id: camZoomRow
						spacing: 10

						IconButton {
							iconName: "zoom-in"
							label: "In"
							onClicked: console.log("Zoom In")
						}
						IconButton {
							iconName: "zoom-out"
							label: "Out"
							onClicked: console.log("Zoom Out")
						}
						IconButton {
							iconName: "zoom-fit-best"
							label: "Quick"
							onClicked: console.log("Quick Zoom")
						}
					}
				}
			}

			// MISSION section
			Rectangle {
				height: missionCol.implicitHeight + 20
				width: missionRow.implicitWidth + 20
				color: "#1c1f26"
				radius: 5

				Column {
					id: missionCol
					anchors.centerIn: parent
					spacing: 3

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: "MISSION"
						color: "#6b7a8d"
						font.pixelSize: 7
						font.letterSpacing: 1
					}

					Row {
						id: missionRow
						spacing: 10

						IconButton {
							iconName: "dialog-ok"
							label: "Accept"
							labelColor: "#6bffb8"
							onClicked: console.log("Accept Path")
						}
						IconButton {
							iconName: "dialog-cancel"
							label: "Cancel"
							labelColor: "#ff6b6b"
							onClicked: console.log("Cancel Path")
						}
					}
				}
			}

			// CONTROLS section
			Rectangle {
				height: camControlsCol.implicitHeight + 20
				width: camControlsRow.implicitWidth + 20
				color: "#1c1f26"
				radius: 5

				Column {
					id: camControlsCol
					anchors.centerIn: parent
					spacing: 3

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: "CONTROLS"
						color: "#6b7a8d"
						font.pixelSize: 7
						font.letterSpacing: 1
					}

					Row {
						id: camControlsRow
						spacing: 10

						IconButton {
							iconName: "view-grid"
							label: "Grid"
							onClicked: console.log("Toggle Grid")
						}
						IconButton {
							iconName: "camera-photo"
							label: "Capture"
							onClicked: console.log("Take Picture")
						}

						IconButton {
							id: camToggle
							property bool isOpen: true
							iconName: isOpen ? "camera-on" : "camera-off"
							label: isOpen ? "Close" : "Open"
							labelColor: isOpen ? "#ff6b6b" : "#6bffb8"
							onClicked: {
								isOpen = !isOpen;
								console.log(isOpen ? "Camera Opened" : "Camera Closed");
							}
						}
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
