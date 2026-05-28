pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// AltitudeTape - vertical tape with drag-to-set target altitude
//
// Public API:
//   altitude       : real  - current altitude in metres
//   darkMode       : bool  - adapt colours for dark backgrounds
//   targetAltitude : real  - confirmed target (0 = none)
//   targetLocked   : bool  - true after SET
//   setTarget(alt)         - programmatically lock a target
//   clearTarget()          - clear target, emits targetReset()
//   signal targetConfirmed(real)
//   signal targetReset()

Item {
	id: root

	property real altitude: 0
	property bool darkMode: false
	property bool liveEdit: false
	property real minimumAltitude: 0

	readonly property real targetAltitude: _targetAlt
	readonly property bool targetLocked: _targetLocked

	signal targetConfirmed(real target)
	signal targetEdited(real target)
	signal targetReset

	function setTarget(alt) {
		_targetAlt = Math.max(root.minimumAltitude, alt);
		_targetLocked = true;
		_tapeOffsetPx = 0;
		root.targetConfirmed(_targetAlt);
	}

	function clearTarget() {
		_tapeOffsetPx = 0;
		_targetLocked = false;
		_targetAlt = root.minimumAltitude;
		root.targetReset();
	}

	// private
	readonly property real _ppm: 6.0
	property real _tapeOffsetPx: 0
	property real _liveStartAltitude: 0
	property real _liveEditAltitude: altitude
	property bool _liveDragActive: false
	property bool _targetLocked: false
	property real _targetAlt: 0
	readonly property real _displayAltitude: liveEdit && _liveDragActive ? _liveEditAltitude : altitude
	readonly property real _tapeCenterAlt: liveEdit ? _displayAltitude : altitude + _tapeOffsetPx / _ppm

	// layout constants
	readonly property real _rulerWidth: 14
	readonly property real _labelWidth: 56
	readonly property real _numberGap: 30
	readonly property real _tickMajorRatio: 0.35
	readonly property real _tickMinorRatio: 0.18

	opacity: enabled ? 1.0 : 0.0
	clip: true
	implicitWidth: _labelWidth + _rulerWidth + _numberGap
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
				position: 0.4
				color: "transparent"
			}
			GradientStop {
				position: 1.0
				color: root.darkMode ? "#cc1a1a2e" : "#c8e0e0e0"
			}
		}
	}

	// Ruler canvas — rightmost strip, draws ticks + numbers
	Canvas {
		id: tapeCanvas
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		width: root._rulerWidth + root._numberGap
		z: 1

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
			var tickRight = w;
			var tickLenMajor = w * root._tickMajorRatio;
			var tickLenMinor = w * root._tickMinorRatio;

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
					// tick
					ctx.strokeStyle = root.darkMode ? "#aaaaaa" : "#444444";
					ctx.lineWidth = 1.2;
					ctx.beginPath();
					ctx.moveTo(tickRight - tickLenMajor, y);
					ctx.lineTo(tickRight, y);
					ctx.stroke();

					// number — left of tick
					ctx.fillStyle = root.darkMode ? "#cccccc" : "#333333";
					ctx.font = "bold 8px monospace";
					ctx.textAlign = "right";
					ctx.fillText(a.toFixed(0), tickRight - tickLenMajor - 2, y + 3);
				} else {
					ctx.strokeStyle = root.darkMode ? "#666666" : "#888888";
					ctx.lineWidth = 0.6;
					ctx.beginPath();
					ctx.moveTo(tickRight - tickLenMinor, y);
					ctx.lineTo(tickRight, y);
					ctx.stroke();
				}
			}
		}
	}

	// Indicator labels — full component width, above canvas
	Item {
		anchors.fill: parent
		z: 5

		// current altitude / live-edit waypoint indicator
		Row {
			id: currentLabel
			y: root.height / 2 - height / 2 + (root.liveEdit ? 0 : root._tapeOffsetPx)
			x: 2
			spacing: 2

			Text {
				text: root._fmtAlt(root._displayAltitude)
				color: root.darkMode ? "#cccccc" : "#333333"
				font {
					pixelSize: 10
					bold: true
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
					colorizationColor: root.darkMode ? "#cccccc" : "#333333"
				}
			}
		}

		// target altitude indicator
		Row {
			id: targetLabel
			x: 2
			spacing: 2

			visible: !root.liveEdit && (root._tapeOffsetPx !== 0 || root._targetLocked)

			y: {
				if (root._targetLocked)
					return root.height / 2 - height / 2 - (root._targetAlt - root.altitude) * root._ppm;
				return root.height / 2 - height / 2;
			}

			Text {
				text: root._targetLocked ? root._fmtAlt(root._targetAlt) : root._fmtAlt(root._tapeCenterAlt)
				color: root.darkMode ? "#5a9aef" : "#1a50a0"
				font {
					pixelSize: 10
					bold: true
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
					colorizationColor: root.darkMode ? "#5a9aef" : "#1a50a0"
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
			root._liveStartAltitude = root.altitude;
			root._liveEditAltitude = root.altitude;
			root._liveDragActive = root.liveEdit;
			if (root.liveEdit) {
				root._tapeOffsetPx = 0;
			} else if (root._targetLocked) {
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
			if (root.liveEdit) {
				root._liveEditAltitude = Math.max(root.minimumAltitude, root._liveStartAltitude + next / root._ppm);
				root._targetAlt = root._liveEditAltitude;
				root._targetLocked = true;
				root.targetEdited(root._targetAlt);
				root._tapeOffsetPx = 0;
				return;
			}
			if (root.altitude + next / root._ppm < root.minimumAltitude)
				next = (root.minimumAltitude - root.altitude) * root._ppm;
			root._tapeOffsetPx = next;
		}

		onReleased: {
			root._liveDragActive = false;
			if (root.liveEdit)
				root._targetLocked = false;
		}
		onCanceled: {
			root._liveDragActive = false;
			if (root.liveEdit)
				root._targetLocked = false;
		}
	}

	// fixed position buttons
	Button {
		id: setBtn
		anchors.right: resetBtn.left
		anchors.rightMargin: 4
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 8
		z: 30

		text: "SET"
		visible: !root.liveEdit && root._tapeOffsetPx !== 0
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
		visible: !root.liveEdit && (root._tapeOffsetPx !== 0 || root._targetLocked)
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

	onAltitudeChanged: {
		if (!liveEdit || !root._liveDragActive)
			root._liveEditAltitude = altitude;
		tapeCanvas.requestPaint();
	}
	on_LiveEditAltitudeChanged: tapeCanvas.requestPaint()
	onHeightChanged: tapeCanvas.requestPaint()
	on_TapeOffsetPxChanged: tapeCanvas.requestPaint()
	onDarkModeChanged: tapeCanvas.requestPaint()
	Component.onCompleted: tapeCanvas.requestPaint()
}
