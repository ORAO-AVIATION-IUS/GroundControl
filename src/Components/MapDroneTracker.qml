pragma ComponentBehavior: Bound

import QtPositioning
import QtQuick

Item {
	id: root

	property var drones: []
	property int maxPathPoints: 5000
	property var trackedPaths: []
	property int revision: 0

	property var _pathStore: ({})

	Component.onCompleted: scheduleRefresh()
	onDronesChanged: scheduleRefresh()

	function coordinateFor(drone) {
		if (!drone)
			return QtPositioning.coordinate();
		return QtPositioning.coordinate(drone.latitude, drone.longitude);
	}

	function hasPosition(drone) {
		return drone && (drone.latitude !== 0 || drone.longitude !== 0);
	}

	function scheduleRefresh() {
		refreshTimer.restart();
	}

	function refresh() {
		const paths = [];
		const activeKeys = {};

		for (let i = 0; i < (drones || []).length; ++i) {
			const drone = drones[i];
			if (!hasPosition(drone))
				continue;

			const key = String(drone.droneUid);
			activeKeys[key] = true;
			const coord = coordinateFor(drone);
			const oldPath = _pathStore[key] || [];

			if (oldPath.length === 0 || coord.distanceTo(oldPath[oldPath.length - 1]) >= 1.0) {
				let newPath = oldPath.concat([coord]);
				if (newPath.length > maxPathPoints)
					newPath = newPath.slice(newPath.length - maxPathPoints);
				_pathStore[key] = newPath;
			}
			paths.push(_pathStore[key]);
		}

		for (const key in _pathStore) {
			if (!activeKeys[key])
				delete _pathStore[key];
		}

		trackedPaths = paths;
		revision += 1;
	}

	Timer {
		id: refreshTimer
		interval: 50
		onTriggered: root.refresh()
	}

	Repeater {
		model: root.drones
		delegate: Item {
			id: droneSignalDelegate

			required property var modelData

			Connections {
				target: droneSignalDelegate.modelData

				function onAltitudeChanged() {
					root.scheduleRefresh();
				}

				function onHeadingChanged() {
					root.scheduleRefresh();
				}

				function onLatitudeChanged() {
					root.scheduleRefresh();
				}

				function onLongitudeChanged() {
					root.scheduleRefresh();
				}
			}
		}
	}
}
