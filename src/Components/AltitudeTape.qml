import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

// AltitudeTape - vertical tape with drag-to-set target altitude
//
// Public API:
//   altitude       : real  - current altitude in metres
//   targetAltitude : real  - confirmed target (0 = none)
//   targetLocked   : bool  - true after SET
//   setTarget(alt)         - programmatically lock a target
//   clearTarget()          - clear target, emits targetReset()
//   signal targetConfirmed(real)
//   signal targetReset()

Item {
	id: root

	property real altitude: 0

	readonly property real targetAltitude: _targetAlt
	readonly property bool targetLocked: _targetLocked

	signal targetConfirmed(real target)
	signal targetReset

	function setTarget(alt) {
		_targetAlt = Math.max(0, alt);
		_targetLocked = true;
		_tapeOffsetPx = 0;
	}

	function clearTarget() {
		_tapeOffsetPx = 0;
		_targetLocked = false;
		_targetAlt = 0;
		root.targetReset();
	}

	// private
	readonly property real _ppm: 6.0
	property real _tapeOffsetPx: 0
	property bool _targetLocked: false
	property real _targetAlt: 0
	readonly property real _tapeCenterAlt: altitude + _tapeOffsetPx / _ppm

	clip: true
	implicitWidth: 110
	implicitHeight: 200

	function _fmtAlt(v) {
		var parts = Math.abs(v).toFixed(1).split(".");
		while (parts[0].length < 3)
			parts[0] = " " + parts[0];
		return (v < 0 ? "-" : "") + parts[0] + "." + parts[1] + "m";
	}

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

	RowLayout {
		anchors.fill: parent
		spacing: 0

		Item {
			Layout.preferredWidth: 54
			Layout.fillHeight: true
			clip: true

			// current altitude label
			Row {
				y: root.height / 2 - height / 2 + root._tapeOffsetPx
				x: 2
				spacing: 2
				z: 10

				Text {
					text: root._fmtAlt(root.altitude)
					color: "#333333"
					font {
						pixelSize: 10
						bold: true
						family: "Courier New"
					}
					anchors.verticalCenter: parent.verticalCenter
				}

				Item {
					width: 16
					height: 14
					anchors.verticalCenter: parent.verticalCenter

					Image {
						id: droneIcon
						anchors.fill: parent
						source: "image://icon/edit-clear-locationbar-ltr"
						fillMode: Image.PreserveAspectFit
					}
					MultiEffect {
						anchors.fill: parent
						source: droneIcon
						colorization: 1.0
						colorizationColor: "#333333"
					}
				}
			}

			// target label
			Row {
				id: targetLabel
				x: 2
				spacing: 2
				z: 10

				visible: root._tapeOffsetPx !== 0 || root._targetLocked

				y: {
					if (root._targetLocked)
						return root.height / 2 - height / 2 - (root._targetAlt - root.altitude) * root._ppm;
					return root.height / 2 - height / 2;
				}

				Text {
					text: root._targetLocked ? root._fmtAlt(root._targetAlt) : root._fmtAlt(root._tapeCenterAlt)
					color: "#1a50a0"
					font {
						pixelSize: 10
						bold: true
						family: "Courier New"
					}
					anchors.verticalCenter: parent.verticalCenter
				}

				Item {
					width: 16
					height: 14
					anchors.verticalCenter: parent.verticalCenter

					Image {
						id: targetIcon
						anchors.fill: parent
						source: "image://icon/edit-clear-locationbar-ltr"
						fillMode: Image.PreserveAspectFit
					}
					MultiEffect {
						anchors.fill: parent
						source: targetIcon
						colorization: 1.0
						colorizationColor: "#1a50a0"
					}
				}
			}
		}

		Canvas {
			id: tapeCanvas
			Layout.fillWidth: true
			Layout.fillHeight: true

			onPaint: {
				var ctx = getContext("2d");
				ctx.reset();

				var majorStep = 10;
				var minorStep = 5;
				var ppm = root._ppm;
				var cy = root.height / 2;
				var w = width;
				var h = height;
				var centerAlt = root._tapeCenterAlt;

				var halfRange = h / (2 * ppm);
				var minAlt = Math.max(0, centerAlt - halfRange);
				var maxAlt = centerAlt + halfRange;
				var startAlt = Math.floor(minAlt / minorStep) * minorStep;

				for (var a = startAlt; a <= maxAlt + minorStep; a += minorStep) {
					var y = cy - (a - centerAlt) * ppm;
					if (y < -12 || y > h + 12)
						continue;

					var isMajor = Math.abs(a % majorStep) < 0.001;

					if (isMajor) {
						ctx.strokeStyle = "#444444";
						ctx.lineWidth = 1.5;
						ctx.beginPath();
						ctx.moveTo(w * 0.55, y);
						ctx.lineTo(w, y);
						ctx.stroke();

						ctx.fillStyle = "#333333";
						ctx.font = "bold 9px monospace";
						ctx.textAlign = "right";
						ctx.fillText(a.toFixed(0), w * 0.50, y + 3);
					} else {
						ctx.strokeStyle = "#888888";
						ctx.lineWidth = 0.8;
						ctx.beginPath();
						ctx.moveTo(w * 0.75, y);
						ctx.lineTo(w, y);
						ctx.stroke();
					}
				}
			}
		}
	}

	MouseArea {
		id: dragArea
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
		z: 0

		property real _startY: 0
		property real _startOffset: 0

		onPressed: function (mouse) {
			if (root._targetLocked) {
				root._tapeOffsetPx = (root._targetAlt - root.altitude) * root._ppm;
				root._targetLocked = false;
			}
			_startY = mouse.y;
			_startOffset = root._tapeOffsetPx;
		}

		onPositionChanged: function (mouse) {
			if (!pressed)
				return;
			var next = _startOffset + (mouse.y - _startY);
			if (root.altitude + next / root._ppm < 0)
				next = -root.altitude * root._ppm;
			root._tapeOffsetPx = next;
		}
	}

	// fixed position buttons, no reflow
	Button {
		id: setBtn
		anchors.right: resetBtn.left
		anchors.rightMargin: 4
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 8
		z: 30

		text: "SET"
		visible: root._tapeOffsetPx !== 0
		onClicked: root.setTarget(root._tapeCenterAlt)

		background: Rectangle {
			radius: 3
			color: setBtn.pressed ? "#1a4890" : setBtn.hovered ? "#2a58a0" : "#3070c0"
		}

		contentItem: Text {
			text: setBtn.text
			color: "white"
			font {
				pixelSize: 9
				bold: true
				family: "Segoe UI"
			}
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
		}
	}

	Button {
		id: resetBtn
		anchors.right: parent.right
		anchors.rightMargin: 4
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 8
		z: 30

		text: "RESET"
		visible: root._tapeOffsetPx !== 0 || root._targetLocked
		onClicked: root.clearTarget()

		background: Rectangle {
			radius: 3
			color: resetBtn.pressed ? "#8a2010" : resetBtn.hovered ? "#a03020" : "#c04030"
		}

		contentItem: Text {
			text: resetBtn.text
			color: "white"
			font {
				pixelSize: 9
				bold: true
				family: "Segoe UI"
			}
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
		}
	}

	onAltitudeChanged: tapeCanvas.requestPaint()
	onHeightChanged: tapeCanvas.requestPaint()
	on_TapeOffsetPxChanged: tapeCanvas.requestPaint()
	Component.onCompleted: tapeCanvas.requestPaint()
}
