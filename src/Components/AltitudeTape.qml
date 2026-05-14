import QtQuick
import QtQuick.Effects

Item {
	id: root
	property double altitude: 0
	readonly property double pixelsPerMeter: 6.0

	clip: true

	// Gradient background: transparent on left, gray on right
	Rectangle {
		anchors.fill: parent
		gradient: Gradient {
			orientation: Gradient.Horizontal
			GradientStop {
				position: 0.0
				color: "transparent"
			}
			GradientStop {
				position: 1.0
				color: "#e0e0e0"
			}
		}
		radius: 4
	}

	Canvas {
		id: tapeCanvas
		anchors.fill: parent

		onPaint: {
			var ctx = getContext("2d");
			ctx.reset();

			var majorStep = 10;
			var minorStep = 5;
			var ppm = root.pixelsPerMeter;
			var cy = root.height / 2;
			var w = width;
			var h = height;

			// Calculate visible altitude range
			var halfRange = h / (2 * ppm);
			var minAlt = Math.max(0, root.altitude - halfRange);
			var maxAlt = root.altitude + halfRange;

			// Start from nearest minor step below minAlt
			var startAlt = Math.floor(minAlt / minorStep) * minorStep;

			for (var a = startAlt; a <= maxAlt + minorStep; a += minorStep) {
				var y = cy - (a - root.altitude) * ppm;

				// Skip if outside visible area (with small buffer)
				if (y < -12 || y > h + 12)
					continue;

				var isMajor = Math.abs(a % majorStep) < 0.001;

				if (isMajor) {
					// Major tick (dark for white bg)
					ctx.strokeStyle = "#444444";
					ctx.lineWidth = 1.5;
					ctx.beginPath();
					ctx.moveTo(w * 0.67, y);
					ctx.lineTo(w, y);
					ctx.stroke();

					// Numbers right-aligned, ending before ticks start
					ctx.fillStyle = "#333333";
					ctx.font = "bold 9px sans-serif";
					ctx.textAlign = "right";
					ctx.fillText(a.toFixed(0), w * 0.60, y + 3);
				} else {
					// Minor tick
					ctx.strokeStyle = "#888888";
					ctx.lineWidth = 0.8;
					ctx.beginPath();
					ctx.moveTo(w * 0.80, y);
					ctx.lineTo(w, y);
					ctx.stroke();
				}
			}
		}
	}

	// Repaint triggers
	onAltitudeChanged: tapeCanvas.requestPaint()
	onHeightChanged: tapeCanvas.requestPaint()
	Component.onCompleted: tapeCanvas.requestPaint()

	// Indicator row: altitude text + icon, both colorized dark
	Row {
		id: indicatorRow
		anchors.verticalCenter: parent.verticalCenter
		anchors.left: parent.left
		anchors.leftMargin: 2
		spacing: 2
		z: 10

		Text {
			text: root.altitude.toFixed(1) + "m"
			color: "#333333"
			font.pixelSize: 8
			font.bold: true
			anchors.verticalCenter: parent.verticalCenter
		}

		Item {
			width: 20
			height: 16

			Image {
				id: indicatorImage
				anchors.fill: parent
				source: "image://icon/edit-clear-locationbar-ltr"
				fillMode: Image.PreserveAspectFit
			}

			MultiEffect {
				anchors.fill: parent
				source: indicatorImage
				colorization: 1.0
				colorizationColor: "#333333"
			}
		}
	}
}
