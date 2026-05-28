pragma ComponentBehavior: Bound

import QtPositioning
import QtQuick

MouseArea {
	id: root

	property var targetMap
	property var drones: []
	property int followedDroneUid: -1
	property bool threeD: true
	property int mapMode: 0
	property string activePlanningTool: "edit"
	property string activeTrackingTool: ""
	property var missionItems: []
	property var hoveredCoordinate: QtPositioning.coordinate()
	property point _lastPointerPoint: Qt.point(0, 0)
	property bool _hasPointerOnMap: false

	signal droneClicked(int droneUid)
	signal missionMapClicked(var coordinate)
	signal homeMapClicked(var coordinate)
	signal missionItemClicked(int index)
	signal missionItemMoved(int index, var coordinate)
	signal missionSegmentInsertRequested(int segmentIndex, var coordinate)
	signal userMovedMap

	anchors.fill: parent
	acceptedButtons: Qt.LeftButton | Qt.RightButton
	hoverEnabled: true
	preventStealing: true
	cursorShape: Qt.ArrowCursor

	property point lastPoint
	property point pressPoint
	property real velocityX: 0
	property real velocityY: 0
	property bool inertiaActive: false
	property bool movedSincePress: false
	property bool movementNotified: false
	property int draggedMissionIndex: -1

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
	readonly property real kClickMoveThreshold: 4

	property var anchorCoord

	function coordinateFor(drone) {
		if (!drone)
			return QtPositioning.coordinate();
		return QtPositioning.coordinate(drone.latitude, drone.longitude);
	}

	function hasPosition(drone) {
		return drone && (drone.latitude !== 0 || drone.longitude !== 0);
	}

	function clampTilt(value) {
		return Math.max(kMinTilt, Math.min(kMaxTilt, value));
	}

	function clearHoveredCoordinate() {
		_hasPointerOnMap = false;
		hoveredCoordinate = QtPositioning.coordinate();
	}

	function droneUidAt(point) {
		const clickCoord = targetMap.toCoordinate(point, false);
		if (!clickCoord.isValid)
			return -1;

		const onePixelCoord = targetMap.toCoordinate(Qt.point(point.x + 1, point.y), false);
		const metersPerPixel = onePixelCoord.isValid ? clickCoord.distanceTo(onePixelCoord) : 1;
		const thresholdMeters = Math.max(8, metersPerPixel * 24);
		let bestUid = -1;
		let bestDistance = thresholdMeters;

		for (let i = 0; i < (drones || []).length; ++i) {
			const drone = drones[i];
			if (!hasPosition(drone))
				continue;
			const distance = clickCoord.distanceTo(coordinateFor(drone));
			if (distance <= bestDistance) {
				bestDistance = distance;
				bestUid = drone.droneUid;
			}
		}
		return bestUid;
	}

	function missionItemAt(point) {
		const clickCoord = targetMap.toCoordinate(point, false);
		if (!clickCoord || !clickCoord.isValid)
			return -1;

		const onePixelCoord = targetMap.toCoordinate(Qt.point(point.x + 1, point.y), false);
		const metersPerPixel = onePixelCoord && onePixelCoord.isValid ? clickCoord.distanceTo(onePixelCoord) : 1;
		const thresholdMeters = Math.max(6, metersPerPixel * 18);
		let bestIndex = -1;
		let bestDistance = thresholdMeters;

		for (let i = 0; i < (missionItems || []).length; ++i) {
			const item = missionItems[i];
			const coord = QtPositioning.coordinate(item.latitude, item.longitude);
			const distance = clickCoord.distanceTo(coord);
			if (distance <= bestDistance) {
				bestDistance = distance;
				bestIndex = i;
			}
		}
		return bestIndex;
	}

	function missionInsertHandleAt(point) {
		const clickCoord = targetMap.toCoordinate(point, false);
		if (mapMode !== 1 || !clickCoord || !clickCoord.isValid || !missionItems || missionItems.length < 2)
			return -1;

		const onePixelCoord = targetMap.toCoordinate(Qt.point(point.x + 1, point.y), false);
		const metersPerPixel = onePixelCoord && onePixelCoord.isValid ? clickCoord.distanceTo(onePixelCoord) : 1;
		const thresholdMeters = Math.max(6, metersPerPixel * 18);
		let bestIndex = -1;
		let bestDistance = thresholdMeters;

		for (let i = 0; i < missionItems.length - 1; ++i) {
			const a = QtPositioning.coordinate(missionItems[i].latitude, missionItems[i].longitude);
			const b = QtPositioning.coordinate(missionItems[i + 1].latitude, missionItems[i + 1].longitude);
			const mid = a.atDistanceAndAzimuth(a.distanceTo(b) * 0.5, a.azimuthTo(b));
			const distance = clickCoord.distanceTo(mid);
			if (distance <= bestDistance) {
				bestDistance = distance;
				bestIndex = i;
			}
		}
		return bestIndex;
	}

	function missionSegmentMidpoint(segmentIndex) {
		if (segmentIndex < 0 || segmentIndex >= (missionItems || []).length - 1)
			return QtPositioning.coordinate();
		const a = QtPositioning.coordinate(missionItems[segmentIndex].latitude, missionItems[segmentIndex].longitude);
		const b = QtPositioning.coordinate(missionItems[segmentIndex + 1].latitude, missionItems[segmentIndex + 1].longitude);
		return a.atDistanceAndAzimuth(a.distanceTo(b) * 0.5, a.azimuthTo(b));
	}

	function noteMapMovement() {
		if (movementNotified)
			return;
		movementNotified = true;
		userMovedMap();
	}

	function refreshHoveredCoordinate() {
		if (_hasPointerOnMap)
			updateHoveredCoordinate(_lastPointerPoint);
	}

	function updateHoveredCoordinate(point) {
		_lastPointerPoint = point;
		_hasPointerOnMap = true;

		const coordinate = targetMap.toCoordinate(point, false);
		hoveredCoordinate = coordinate && coordinate.isValid ? coordinate : QtPositioning.coordinate();
	}

	function followedDroneCoordinate() {
		for (let i = 0; i < (drones || []).length; ++i) {
			const drone = drones[i];
			if (drone && drone.droneUid === followedDroneUid && hasPosition(drone))
				return coordinateFor(drone);
		}
		return QtPositioning.coordinate();
	}

	function zoomTowardCoordinate(coordinate, delta) {
		const newZoom = Math.max(targetMap.minimumZoomLevel, Math.min(targetMap.maximumZoomLevel, targetMap.zoomLevel + delta));
		if (newZoom === targetMap.zoomLevel)
			return false;

		targetMap.zoomLevel = newZoom;
		targetMap.center = coordinate;
		return true;
	}

	function zoomTowardPoint(px, py, delta) {
		const newZoom = Math.max(targetMap.minimumZoomLevel, Math.min(targetMap.maximumZoomLevel, targetMap.zoomLevel + delta));
		if (newZoom === targetMap.zoomLevel)
			return false;

		const targetCoord = targetMap.toCoordinate(Qt.point(px, py), false);
		targetMap.zoomLevel = newZoom;
		if (!targetCoord || !targetCoord.isValid)
			return true;

		const currentCoord = targetMap.toCoordinate(Qt.point(px, py), false);
		if (currentCoord && currentCoord.isValid)
			targetMap.center = QtPositioning.coordinate(targetMap.center.latitude + targetCoord.latitude - currentCoord.latitude, targetMap.center.longitude + targetCoord.longitude - currentCoord.longitude);
		return true;
	}

	onPressed: function (mouse) {
		lastPoint = Qt.point(mouse.x, mouse.y);
		updateHoveredCoordinate(lastPoint);
		pressPoint = lastPoint;
		anchorCoord = targetMap.toCoordinate(lastPoint, false);
		velocityX = 0;
		velocityY = 0;
		movedSincePress = false;
		movementNotified = false;
		inertiaActive = false;
		inertiaTimer.stop();

		if (dragMode !== modeNone)
			return;

		if (mapMode === 1 && mouse.button === Qt.LeftButton) {
			const missionIndex = missionItemAt(lastPoint);
			if (missionIndex >= 0) {
				draggedMissionIndex = missionIndex;
				cursorShape = Qt.ClosedHandCursor;
				return;
			}
			const segmentIndex = missionInsertHandleAt(lastPoint);
			if (segmentIndex >= 0) {
				missionSegmentInsertRequested(segmentIndex, missionSegmentMidpoint(segmentIndex));
				draggedMissionIndex = segmentIndex + 1;
				cursorShape = Qt.ClosedHandCursor;
				return;
			}
		}

		if (mouse.button === Qt.LeftButton && !(mouse.modifiers & Qt.ControlModifier)) {
			dragMode = modePan;
			cursorShape = Qt.OpenHandCursor;
		} else {
			dragMode = modeRotateTilt;
			cursorShape = Qt.ClosedHandCursor;
		}
	}

	onPositionChanged: function (mouse) {
		const point = Qt.point(mouse.x, mouse.y);
		updateHoveredCoordinate(point);
		const dx = point.x - lastPoint.x;
		const dy = point.y - lastPoint.y;
		const pressDx = point.x - pressPoint.x;
		const pressDy = point.y - pressPoint.y;

		if (Math.sqrt(pressDx * pressDx + pressDy * pressDy) > kClickMoveThreshold) {
			movedSincePress = true;
			if (dragMode === modePan)
				noteMapMovement();
		}

		if (draggedMissionIndex >= 0) {
			const coordinate = targetMap.toCoordinate(point, false);
			if (coordinate && coordinate.isValid)
				missionItemMoved(draggedMissionIndex, coordinate);
		} else if (dragMode === modePan) {
			const cur = targetMap.toCoordinate(point, false);
			if (cur.isValid && anchorCoord.isValid) {
				targetMap.center = QtPositioning.coordinate(targetMap.center.latitude + anchorCoord.latitude - cur.latitude, targetMap.center.longitude + anchorCoord.longitude - cur.longitude);
			}
			velocityX = velocityX * 0.6 + (-dx) * 0.4;
			velocityY = velocityY * 0.6 + (-dy) * 0.4;
		} else if (dragMode === modeRotateTilt) {
			targetMap.bearing += dx * kBearingSensitivity;
			if (threeD)
				targetMap.tilt = clampTilt(targetMap.tilt - dy * kTiltSensitivity);
		}

		lastPoint = point;
	}

	onReleased: function (mouse) {
		if (draggedMissionIndex >= 0) {
			missionItemClicked(draggedMissionIndex);
			draggedMissionIndex = -1;
			dragMode = modeNone;
			cursorShape = Qt.ArrowCursor;
			return;
		}

		if (!movedSincePress && mouse.button === Qt.LeftButton) {
			const point = Qt.point(mouse.x, mouse.y);
			if (mapMode === 1) {
				const missionIndex = missionItemAt(point);
				if (missionIndex >= 0) {
					missionItemClicked(missionIndex);
				} else {
					const coordinate = targetMap.toCoordinate(point, false);
					if (coordinate && coordinate.isValid)
						missionMapClicked(coordinate);
				}
			} else if (mapMode === 2 && activeTrackingTool === "home") {
				const coordinate = targetMap.toCoordinate(point, false);
				if (coordinate && coordinate.isValid)
					homeMapClicked(coordinate);
			} else {
				const uid = droneUidAt(point);
				if (uid >= 0)
					droneClicked(uid);
			}
		}

		if (movedSincePress && mouse.button === Qt.LeftButton && dragMode === modePan) {
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
		draggedMissionIndex = -1;
		dragMode = modeNone;
		cursorShape = Qt.ArrowCursor;
	}

	onExited: clearHoveredCoordinate()

	Timer {
		id: inertiaTimer
		interval: root.kInertiaInterval
		repeat: true

		onTriggered: {
			if (!root.inertiaActive) {
				stop();
				return;
			}

			root.velocityX *= root.kFriction;
			root.velocityY *= root.kFriction;

			if (Math.abs(root.velocityX) < root.kInertiaCutoff && Math.abs(root.velocityY) < root.kInertiaCutoff) {
				root.inertiaActive = false;
				stop();
				return;
			}

			root.targetMap.pan(root.velocityX, root.velocityY);
		}
	}

	onWheel: function (wheel) {
		updateHoveredCoordinate(Qt.point(wheel.x, wheel.y));
		const focusedCoordinate = followedDroneCoordinate();
		const shouldZoomToDrone = focusedCoordinate && focusedCoordinate.isValid;
		const isDiscreteWheel = (wheel.angleDelta.y !== 0) && (wheel.angleDelta.y % 120 === 0) && (Math.abs(wheel.pixelDelta.y) < 1);

		if (isDiscreteWheel) {
			const zoomDir = wheel.angleDelta.y > 0 ? 1 : -1;
			if (shouldZoomToDrone)
				zoomTowardCoordinate(focusedCoordinate, zoomDir * kZoomStep);
			else {
				userMovedMap();
				zoomTowardPoint(wheel.x, wheel.y, zoomDir * kZoomStep);
			}
			return;
		}

		const dx = (wheel.pixelDelta.x !== 0) ? wheel.pixelDelta.x : wheel.angleDelta.x * 0.1;
		const dy = (wheel.pixelDelta.y !== 0) ? wheel.pixelDelta.y : wheel.angleDelta.y * 0.1;

		if (wheel.modifiers & Qt.ControlModifier) {
			if (!shouldZoomToDrone)
				userMovedMap();
			if (Math.abs(dy) >= Math.abs(dx)) {
				if (threeD)
					targetMap.tilt = clampTilt(targetMap.tilt - dy * kTouchpadTiltSensitivity);
			} else {
				targetMap.bearing += dx * kBearingSensitivity;
			}
		} else {
			if (Math.abs(dy) >= Math.abs(dx)) {
				if (shouldZoomToDrone)
					zoomTowardCoordinate(focusedCoordinate, dy * kTouchpadZoomSensitivity);
				else {
					userMovedMap();
					zoomTowardPoint(wheel.x, wheel.y, dy * kTouchpadZoomSensitivity);
				}
			} else {
				if (!shouldZoomToDrone)
					userMovedMap();
				targetMap.bearing += dx * kBearingSensitivity;
			}
		}
	}
}
