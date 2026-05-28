pragma ComponentBehavior: Bound

import Agc.Components
import Agc.Mavlink
import Agc.Style
import QtCore
import QtPositioning
import QtQuick
import QtQuick.Controls
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: dockRoot
	uniqueName: "mapPanel"
	title: qsTr("Map")

	property int mapMode: 0
	property string activePlanningTool: "edit"
	property string activeTrackingTool: ""
	property var missionItems: []
	property int selectedMissionItemIndex: -1
	property int missionRevision: 0
	property real defaultMissionAltitude: 50
	property real defaultMissionSpeed: 8
	property bool returnHomeAfterMission: false
	property bool missionUploaded: false
	property bool missionDirty: false
	property bool missionBusy: false
	property bool missionRunning: false
	property bool missionPaused: false
	property bool waypointConfigOpen: false
	property bool missionLibraryOpen: false
	property string missionDraftName: "Mission"
	property int missionLibraryRevision: 0
	property string missionBusyText: ""
	property string missionErrorText: ""
	property double localHomeLatitude: 0
	property double localHomeLongitude: 0
	property double localHomeAltitude: 0
	property bool localHomeValid: false

	Settings {
		id: missionSettings
		category: "MissionPlanning"
		property string savedMissionPlan: ""
		property string savedMissionPlans: "{}"
	}

	property var _targetStore: ({})
	property bool followSelectedDrone: false

	readonly property int selectedDroneIndex: SwarmManager.selectedDroneIndex
	readonly property var selectedDrone: SwarmManager.selectedDrone
	readonly property alias hoveredCoordinate: mapView.hoveredCoordinate

	onMapModeChanged: {
		if (mapMode !== 1) {
			selectedMissionItemIndex = -1;
			waypointConfigOpen = false;
		}
	}

	onSelectedDroneChanged: {
		if (selectedDrone) {
			var entry = _targetStore[String(selectedDrone.droneUid)];
			if (entry && entry.locked)
				altTape.setTarget(entry.alt);
			else
				altTape.clearTarget();
		} else {
			altTape.clearTarget();
		}
	}

	function hasPosition(drone) {
		return drone && (drone.latitude !== 0 || drone.longitude !== 0);
	}

	function followSelected() {
		if (!selectedDrone || !hasPosition(selectedDrone))
			return;
		mapView.centerOn(mapView.coordinateFor(selectedDrone));
	}

	function selectDroneByUid(uid) {
		for (let i = 0; i < SwarmManager.droneList.length; ++i) {
			if (SwarmManager.droneList[i].droneUid === uid) {
				SwarmManager.selectDrone(i);
				return;
			}
		}
	}

	function selectedMissionItem() {
		if (selectedMissionItemIndex < 0 || selectedMissionItemIndex >= missionItems.length)
			return null;
		return missionItems[selectedMissionItemIndex];
	}

	function markMissionChanged() {
		missionRevision += 1;
		missionErrorText = "";
		missionRunning = false;
		missionPaused = false;
		if (missionUploaded)
			missionDirty = true;
	}

	function missionStatusText() {
		if (missionBusy)
			return missionBusyText;
		if (missionErrorText !== "")
			return "ERROR";
		if (missionItems.length === 0)
			return "EMPTY";
		if (missionRunning)
			return "RUNNING";
		if (missionPaused)
			return "PAUSED";
		if (missionUploaded && missionDirty)
			return "DIRTY";
		if (missionUploaded)
			return "UPLOADED";
		return "DRAFT";
	}

	function setMissionError(message) {
		missionErrorText = message;
		missionBusy = false;
	}

	function handlePlanMapClick(coordinate) {
		if (activePlanningTool === "waypoint")
			addMissionWaypoint(coordinate);
	}

	function setHomePoint(coordinate, sendToDrone) {
		if (!coordinate || !coordinate.isValid)
			return;
		localHomeLatitude = coordinate.latitude;
		localHomeLongitude = coordinate.longitude;
		localHomeAltitude = selectedDrone && selectedDrone.altitudeMsl ? selectedDrone.altitudeMsl : 0;
		localHomeValid = true;
		if (sendToDrone && selectedDrone && selectedDrone.connected)
			selectedDrone.setHome(localHomeLatitude, localHomeLongitude, localHomeAltitude);
	}

	function ensureVisibleHomePoint() {
		if ((selectedDrone && selectedDrone.homeValid) || localHomeValid)
			return;
		if (selectedDrone && hasPosition(selectedDrone))
			setHomePoint(QtPositioning.coordinate(selectedDrone.latitude, selectedDrone.longitude), false);
	}

	function addMissionWaypoint(coordinate) {
		if (!coordinate || !coordinate.isValid || activePlanningTool !== "waypoint")
			return;
		const items = missionItems.slice();
		items.push(waypointFromCoordinate(coordinate, appendAltitude(), appendSpeed()));
		missionItems = items;
		selectedMissionItemIndex = items.length - 1;
		markMissionChanged();
	}

	function waypointFromCoordinate(coordinate, altitude, speed) {
		return {
			"latitude": coordinate.latitude,
			"longitude": coordinate.longitude,
			"altitude": altitude,
			"speed": speed,
			"speedEnabled": false,
			"acceptanceRadius": 3,
			"acceptanceRadiusEnabled": false,
			"flyThrough": true,
			"loiter": 0,
			"loiterEnabled": false
		};
	}

	function appendAltitude() {
		return missionItems.length > 0 ? missionItems[missionItems.length - 1].altitude : defaultMissionAltitude;
	}

	function appendSpeed() {
		return missionItems.length > 0 ? missionItems[missionItems.length - 1].speed : defaultMissionSpeed;
	}

	function segmentAltitude(segmentIndex) {
		if (segmentIndex < 0 || segmentIndex >= missionItems.length - 1)
			return appendAltitude();
		return (missionItems[segmentIndex].altitude + missionItems[segmentIndex + 1].altitude) * 0.5;
	}

	function segmentSpeed(segmentIndex) {
		if (segmentIndex < 0 || segmentIndex >= missionItems.length - 1)
			return appendSpeed();
		return (missionItems[segmentIndex].speed + missionItems[segmentIndex + 1].speed) * 0.5;
	}

	function nearestMissionSegmentIndex(coordinate) {
		if (!coordinate || !coordinate.isValid || missionItems.length < 2)
			return missionItems.length - 1;
		let bestIndex = 0;
		let bestScore = Number.MAX_VALUE;
		for (let i = 0; i < missionItems.length - 1; ++i) {
			const a = QtPositioning.coordinate(missionItems[i].latitude, missionItems[i].longitude);
			const b = QtPositioning.coordinate(missionItems[i + 1].latitude, missionItems[i + 1].longitude);
			const segmentLength = Math.max(1, a.distanceTo(b));
			const score = a.distanceTo(coordinate) + coordinate.distanceTo(b) - segmentLength;
			if (score < bestScore) {
				bestScore = score;
				bestIndex = i;
			}
		}
		return bestIndex;
	}

	function insertMissionWaypoint(coordinate) {
		if (!coordinate || !coordinate.isValid)
			return;
		const segmentIndex = missionItems.length < 2 ? missionItems.length - 1 : nearestMissionSegmentIndex(coordinate);
		insertMissionWaypointAtSegment(segmentIndex, coordinate);
	}

	function insertMissionWaypointAtSegment(segmentIndex, coordinate) {
		if (!coordinate || !coordinate.isValid)
			return;
		const items = missionItems.slice();
		const insertIndex = missionItems.length < 2 ? missionItems.length : Math.max(0, Math.min(segmentIndex + 1, missionItems.length));
		items.splice(insertIndex, 0, waypointFromCoordinate(coordinate, segmentAltitude(segmentIndex), segmentSpeed(segmentIndex)));
		missionItems = items;
		selectedMissionItemIndex = insertIndex;
		markMissionChanged();
	}

	function moveMissionWaypoint(index, coordinate) {
		if (index < 0 || index >= missionItems.length || !coordinate || !coordinate.isValid)
			return;
		const items = missionItems.slice();
		items[index] = Object.assign({}, items[index], {
			"latitude": coordinate.latitude,
			"longitude": coordinate.longitude
		});
		missionItems = items;
		selectedMissionItemIndex = index;
		markMissionChanged();
	}

	function setSelectedMissionField(fieldName, value, minimumValue) {
		if (selectedMissionItemIndex < 0 || selectedMissionItemIndex >= missionItems.length)
			return;
		const items = missionItems.slice();
		const update = {};
		update[fieldName] = Math.max(minimumValue, value);
		items[selectedMissionItemIndex] = Object.assign({}, items[selectedMissionItemIndex], update);
		missionItems = items;
		markMissionChanged();
	}

	function setSelectedMissionAltitude(altitude) {
		setSelectedMissionField("altitude", altitude, 5);
	}

	function setSelectedMissionSpeed(speed) {
		setSelectedMissionField("speed", speed, 0.5);
	}

	function setSelectedMissionAcceptanceRadius(radius) {
		setSelectedMissionField("acceptanceRadius", radius, 0.5);
	}

	function setSelectedMissionLoiter(loiter) {
		setSelectedMissionField("loiter", loiter, 0);
	}

	function setSelectedMissionOptionEnabled(fieldName, enabled) {
		if (selectedMissionItemIndex < 0 || selectedMissionItemIndex >= missionItems.length)
			return;
		const items = missionItems.slice();
		const update = {};
		update[fieldName] = enabled;
		items[selectedMissionItemIndex] = Object.assign({}, items[selectedMissionItemIndex], update);
		missionItems = items;
		markMissionChanged();
	}

	function setSelectedMissionFlyThrough(flyThrough) {
		if (selectedMissionItemIndex < 0 || selectedMissionItemIndex >= missionItems.length)
			return;
		const items = missionItems.slice();
		items[selectedMissionItemIndex] = Object.assign({}, items[selectedMissionItemIndex], {
			"flyThrough": flyThrough
		});
		missionItems = items;
		markMissionChanged();
	}

	function removeSelectedMissionWaypoint() {
		if (selectedMissionItemIndex < 0 || selectedMissionItemIndex >= missionItems.length)
			return;
		const items = missionItems.slice();
		items.splice(selectedMissionItemIndex, 1);
		missionItems = items;
		selectedMissionItemIndex = Math.min(selectedMissionItemIndex, items.length - 1);
		markMissionChanged();
	}

	function clearLocalMission() {
		missionItems = [];
		selectedMissionItemIndex = -1;
		waypointConfigOpen = false;
		returnHomeAfterMission = false;
		missionUploaded = false;
		missionDirty = false;
		missionBusy = false;
		missionRunning = false;
		missionPaused = false;
		missionErrorText = "";
		missionRevision += 1;
	}

	function missionDistanceMeters() {
		let distance = 0;
		for (let i = 1; i < missionItems.length; ++i) {
			const a = QtPositioning.coordinate(missionItems[i - 1].latitude, missionItems[i - 1].longitude);
			const b = QtPositioning.coordinate(missionItems[i].latitude, missionItems[i].longitude);
			distance += a.distanceTo(b);
		}
		return distance;
	}

	function missionDistanceText() {
		const distance = missionDistanceMeters();
		return distance >= 1000 ? qsTr("%1 km").arg((distance / 1000).toFixed(2)) : qsTr("%1 m").arg(Math.round(distance));
	}

	function savedMissionStore() {
		try {
			const store = JSON.parse(missionSettings.savedMissionPlans || "{}");
			return store && typeof store === "object" ? store : {};
		} catch (error) {
			return {};
		}
	}

	function savedMissionNames() {
		void missionLibraryRevision;
		return Object.keys(savedMissionStore()).sort();
	}

	function selectedSavedMissionName() {
		const names = savedMissionNames();
		return names.length > 0 ? names[missionPlanSelector.currentIndex] : "";
	}

	function saveMissionDraft(name) {
		const trimmedName = String(name || "").trim();
		if (trimmedName === "") {
			setMissionError(qsTr("Name the mission before saving"));
			return;
		}
		if (missionItems.length === 0) {
			setMissionError(qsTr("No mission to save"));
			return;
		}
		const store = savedMissionStore();
		store[trimmedName] = {
			"version": 1,
			"name": trimmedName,
			"returnHomeAfterMission": returnHomeAfterMission,
			"items": missionItems
		};
		missionSettings.savedMissionPlans = JSON.stringify(store);
		missionSettings.savedMissionPlan = JSON.stringify(store[trimmedName]);
		missionDraftName = trimmedName;
		missionLibraryRevision += 1;
		missionErrorText = "";
		if (selectedDrone)
			selectedDrone.log(selectedDrone.droneName, qsTr("Mission draft saved: %1").arg(trimmedName), "info");
	}

	function loadMissionDraft(name) {
		const store = savedMissionStore();
		const trimmedName = String(name || "").trim();
		const plan = store[trimmedName];
		if (!plan) {
			setMissionError(qsTr("Select a saved mission draft"));
			return;
		}
		if (!plan.items || !Array.isArray(plan.items)) {
			setMissionError(qsTr("Saved mission draft is invalid"));
			return;
		}
		missionItems = plan.items;
		selectedMissionItemIndex = missionItems.length > 0 && mapMode === 1 ? 0 : -1;
		returnHomeAfterMission = plan.returnHomeAfterMission === true;
		missionDraftName = trimmedName;
		missionUploaded = false;
		missionDirty = false;
		missionBusy = false;
		missionRunning = false;
		missionPaused = false;
		missionErrorText = "";
		missionRevision += 1;
	}

	function deleteMissionDraft(name) {
		const trimmedName = String(name || "").trim();
		const store = savedMissionStore();
		if (!store[trimmedName])
			return;
		delete store[trimmedName];
		missionSettings.savedMissionPlans = JSON.stringify(store);
		missionLibraryRevision += 1;
	}

	function validateMissionDraft() {
		if (!selectedDrone)
			return qsTr("Select a drone before uploading");
		if (!selectedDrone.connected)
			return qsTr("Selected drone is not connected");
		if (missionItems.length < 2)
			return qsTr("Add at least 2 waypoints");
		for (let i = 0; i < missionItems.length; ++i) {
			const item = missionItems[i];
			if (item.altitude < 5)
				return qsTr("Waypoint %1 altitude is too low").arg(i + 1);
			if (item.speedEnabled && item.speed <= 0)
				return qsTr("Waypoint %1 speed is invalid").arg(i + 1);
		}
		return "";
	}

	function requestMissionUpload() {
		const error = validateMissionDraft();
		if (error !== "") {
			setMissionError(error);
			if (selectedDrone)
				selectedDrone.log(selectedDrone.droneName, error, "warning");
			return;
		}
		missionBusy = true;
		missionBusyText = "UPLOADING";
		missionErrorText = "";
		selectedDrone.uploadMission(missionItems, returnHomeAfterMission);
	}

	function requestMissionStart() {
		if (!selectedDrone || !selectedDrone.connected) {
			setMissionError(qsTr("Selected drone is not connected"));
			return;
		}
		if (!selectedDrone.readyToFly) {
			setMissionError(qsTr("Drone is not ready to fly"));
			return;
		}
		if (!missionUploaded || missionDirty) {
			setMissionError(qsTr("Upload current mission before starting"));
			return;
		}
		if (!selectedDrone.sensorGps) {
			setMissionError(qsTr("GPS is not ready"));
			return;
		}
		if (selectedDrone.battery <= 20) {
			setMissionError(qsTr("Battery is too low for mission start"));
			return;
		}
		missionBusy = true;
		missionBusyText = "STARTING";
		missionErrorText = "";
		selectedDrone.startMission();
	}

	function requestMissionPause() {
		if (!selectedDrone || !selectedDrone.connected)
			return;
		missionBusy = true;
		missionBusyText = "PAUSING";
		selectedDrone.pauseMission();
	}

	function requestMissionClear() {
		if (selectedDrone && selectedDrone.connected) {
			missionBusy = true;
			missionBusyText = "CLEARING";
			selectedDrone.clearMission();
		}
		clearLocalMission();
	}

	function requestMissionDownload() {
		if (!selectedDrone || !selectedDrone.connected) {
			setMissionError(qsTr("Selected drone is not connected"));
			return;
		}
		missionBusy = true;
		missionBusyText = "DOWNLOADING";
		missionErrorText = "";
		selectedDrone.downloadMission();
	}

	Item {
		anchors.fill: parent

		Connections {
			target: dockRoot.selectedDrone
			ignoreUnknownSignals: true

			function onMissionUploadFinished(success, message) {
				dockRoot.missionBusy = false;
				if (success) {
					dockRoot.missionUploaded = true;
					dockRoot.missionDirty = false;
					dockRoot.missionRunning = false;
					dockRoot.missionPaused = false;
					dockRoot.missionErrorText = "";
				} else {
					dockRoot.missionErrorText = message;
				}
			}

			function onMissionStartFinished(success, message) {
				dockRoot.missionBusy = false;
				if (success) {
					dockRoot.missionRunning = true;
					dockRoot.missionPaused = false;
					dockRoot.missionErrorText = "";
				} else {
					dockRoot.missionErrorText = message;
				}
			}

			function onMissionPauseFinished(success, message) {
				dockRoot.missionBusy = false;
				if (success) {
					dockRoot.missionRunning = false;
					dockRoot.missionPaused = true;
					dockRoot.missionErrorText = "";
				} else {
					dockRoot.missionErrorText = message;
				}
			}

			function onMissionClearFinished(success, message) {
				dockRoot.missionBusy = false;
				if (success) {
					dockRoot.missionUploaded = false;
					dockRoot.missionDirty = false;
					dockRoot.missionRunning = false;
					dockRoot.missionPaused = false;
					dockRoot.missionErrorText = "";
				} else {
					dockRoot.missionErrorText = message;
				}
			}

			function onMissionDownloadFinished(success, message, missionItems, returnToLaunchAfterMission) {
				dockRoot.missionBusy = false;
				if (success) {
					dockRoot.missionItems = missionItems;
					dockRoot.selectedMissionItemIndex = missionItems.length > 0 ? 0 : -1;
					dockRoot.returnHomeAfterMission = returnToLaunchAfterMission;
					dockRoot.missionUploaded = missionItems.length > 0;
					dockRoot.missionDirty = false;
					dockRoot.missionRunning = false;
					dockRoot.missionPaused = false;
					dockRoot.missionErrorText = "";
					dockRoot.missionRevision += 1;
				} else {
					dockRoot.missionErrorText = message;
				}
			}
		}

		Repeater {
			model: SwarmManager.droneList
			delegate: Item {
				id: followDelegate

				required property var modelData

				Connections {
					target: followDelegate.modelData

					function onLatitudeChanged() {
						if (dockRoot.followSelectedDrone && followDelegate.modelData === dockRoot.selectedDrone)
							dockRoot.followSelected();
					}

					function onLongitudeChanged() {
						if (dockRoot.followSelectedDrone && followDelegate.modelData === dockRoot.selectedDrone)
							dockRoot.followSelected();
					}
				}
			}
		}

		MapView {
			id: mapView
			anchors.fill: parent

			threeD: mapSettings.is3d
			lightMode: !mapSettings.isDark
			satelliteMode: mapSettings.isSatellite
			drones: SwarmManager.droneList
			selectedDroneUid: dockRoot.selectedDrone ? dockRoot.selectedDrone.droneUid : -1
			followedDroneUid: dockRoot.followSelectedDrone && dockRoot.selectedDrone ? dockRoot.selectedDrone.droneUid : -1
			mapMode: dockRoot.mapMode
			activePlanningTool: dockRoot.activePlanningTool
			activeTrackingTool: dockRoot.activeTrackingTool
			missionItems: dockRoot.missionItems
			selectedMissionItemIndex: dockRoot.mapMode === 1 ? dockRoot.selectedMissionItemIndex : -1
			currentMissionItemIndex: dockRoot.selectedDrone ? dockRoot.selectedDrone.wpCurrent : 0
			homeLatitude: dockRoot.selectedDrone && dockRoot.selectedDrone.homeValid ? dockRoot.selectedDrone.homeLatitude : dockRoot.localHomeLatitude
			homeLongitude: dockRoot.selectedDrone && dockRoot.selectedDrone.homeValid ? dockRoot.selectedDrone.homeLongitude : dockRoot.localHomeLongitude
			homeValid: dockRoot.selectedDrone && dockRoot.selectedDrone.homeValid ? true : dockRoot.localHomeValid
			returnHomeAfterMission: dockRoot.returnHomeAfterMission
			missionRevision: dockRoot.missionRevision
			onDroneClicked: function (droneUid) {
				dockRoot.selectDroneByUid(droneUid);
			}
			onMissionMapClicked: function (coordinate) {
				dockRoot.handlePlanMapClick(coordinate);
			}
			onMissionItemClicked: function (index) {
				dockRoot.selectedMissionItemIndex = index;
			}
			onMissionItemMoved: function (index, coordinate) {
				dockRoot.moveMissionWaypoint(index, coordinate);
			}
			onMissionSegmentInsertRequested: function (segmentIndex, coordinate) {
				dockRoot.insertMissionWaypointAtSegment(segmentIndex, coordinate);
			}
			onHomeMapClicked: function (coordinate) {
				dockRoot.setHomePoint(coordinate, true);
				dockRoot.activeTrackingTool = "";
			}
			onUserMovedMap: dockRoot.followSelectedDrone = false
		}

		MapModeToolbar {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.margins: Style.overlayMargin
			mapMode: dockRoot.mapMode
			activePlanningTool: dockRoot.activePlanningTool
			activeTrackingTool: dockRoot.activeTrackingTool
			returnHomeAfterMission: dockRoot.returnHomeAfterMission
			canReturnFromSelectedWaypoint: dockRoot.selectedMissionItemIndex === dockRoot.missionItems.length - 1 && dockRoot.missionItems.length > 0
			followSelectedDrone: dockRoot.followSelectedDrone
			canFollowSelectedDrone: dockRoot.selectedDrone ? dockRoot.hasPosition(dockRoot.selectedDrone) : false
			onMapModeRequested: function (mode) {
				dockRoot.mapMode = mode;
				if (mode !== 2)
					dockRoot.activeTrackingTool = "";
				if (mode === 1 && (dockRoot.activePlanningTool === "" || dockRoot.activePlanningTool === "home"))
					dockRoot.activePlanningTool = "edit";
			}
			onPlanningToolRequested: function (tool) {
				if (tool === "clear") {
					dockRoot.clearLocalMission();
				} else if (tool === "return") {
					dockRoot.returnHomeAfterMission = !dockRoot.returnHomeAfterMission;
					if (dockRoot.returnHomeAfterMission)
						dockRoot.ensureVisibleHomePoint();
					dockRoot.markMissionChanged();
				} else {
					dockRoot.activePlanningTool = tool;
				}
			}
			onFollowSelectedDroneRequested: function (follow) {
				dockRoot.followSelectedDrone = follow;
				if (follow)
					dockRoot.followSelected();
			}
			onTrackingToolRequested: function (tool) {
				if (tool === "home")
					dockRoot.activeTrackingTool = dockRoot.activeTrackingTool === "home" ? "" : "home";
				else
					console.log("Tracking tool", tool);
			}
		}

		ButtonGroup {
			id: missionOverlay
			z: 5
			anchors.left: parent.left
			anchors.bottom: parent.bottom
			anchors.margins: Style.overlayMargin
			title: "MISSION  " + dockRoot.missionStatusText() + "  " + dockRoot.missionItems.length + " WP  " + dockRoot.missionDistanceText() + (dockRoot.returnHomeAfterMission ? "  RTH" : "")
			horizontal: true
			visible: dockRoot.mapMode === 1 || dockRoot.missionItems.length > 0

			IconButton {
				iconName: "document-send"
				label: "Upload"
				enabled: !dockRoot.missionBusy && dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.missionItems.length >= 2
				onClicked: dockRoot.requestMissionUpload()
			}
			IconButton {
				iconName: "document-open"
				label: "Download"
				enabled: !dockRoot.missionBusy && dockRoot.selectedDrone && dockRoot.selectedDrone.connected
				onClicked: dockRoot.requestMissionDownload()
			}
			IconButton {
				iconName: "document-save"
				label: "Plans"
				enabled: !dockRoot.missionBusy
				checkable: true
				checked: dockRoot.missionLibraryOpen
				onClicked: dockRoot.missionLibraryOpen = checked
			}
			IconButton {
				iconName: "media-playback-start"
				label: "Start"
				labelColor: "#6bffb8"
				enabled: !dockRoot.missionBusy && dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.missionUploaded && !dockRoot.missionDirty
				onClicked: dockRoot.requestMissionStart()
			}
			IconButton {
				iconName: "media-playback-pause"
				label: "Pause"
				labelColor: "#ffd06b"
				enabled: !dockRoot.missionBusy && dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.missionRunning
				onClicked: dockRoot.requestMissionPause()
			}
			IconButton {
				iconName: "edit-clear"
				label: "Clear"
				labelColor: "#ff6b6b"
				enabled: !dockRoot.missionBusy && (dockRoot.missionItems.length > 0 || dockRoot.missionUploaded)
				onClicked: dockRoot.requestMissionClear()
			}
			Text {
				color: "#ff6b6b"
				font.pixelSize: 10
				text: dockRoot.missionErrorText
				visible: dockRoot.missionErrorText !== ""
			}
		}

		ButtonGroup {
			id: missionLibraryPanel
			z: 6
			anchors.left: missionOverlay.left
			anchors.bottom: missionOverlay.top
			anchors.bottomMargin: Style.sectionSpacing
			title: "MISSION PLANS"
			visible: missionOverlay.visible && dockRoot.missionLibraryOpen

			Column {
				spacing: 4

				Rectangle {
					width: 190
					height: 26
					color: missionNameInput.activeFocus ? "#253247" : "#182231"
					border.color: missionNameInput.activeFocus ? Style.iconBtnCheckedBg : "#5b6b82"
					border.width: missionNameInput.activeFocus ? 2 : 1
					radius: 4

					TextInput {
						id: missionNameInput
						anchors.fill: parent
						anchors.leftMargin: 7
						anchors.rightMargin: 7
						verticalAlignment: TextInput.AlignVCenter
						text: dockRoot.missionDraftName
						color: Style.iconBtnLabelColor
						selectedTextColor: "#ffffff"
						selectionColor: Style.iconBtnCheckedBg
						font.pixelSize: 11
						onEditingFinished: dockRoot.missionDraftName = text
					}
				}

				ComboBox {
					id: missionPlanSelector
					width: 190
					height: 26
					model: dockRoot.savedMissionNames()
					onActivated: function (index) {
						if (index >= 0 && index < model.length)
							dockRoot.missionDraftName = model[index];
					}
				}

				Row {
					spacing: Style.sectionSpacing

					IconButton {
						iconName: "document-save"
						label: "Save"
						enabled: dockRoot.missionItems.length > 0
						onClicked: dockRoot.saveMissionDraft(missionNameInput.text)
					}
					IconButton {
						iconName: "document-open-recent"
						label: "Load"
						enabled: missionPlanSelector.count > 0
						onClicked: dockRoot.loadMissionDraft(dockRoot.selectedSavedMissionName())
					}
					IconButton {
						iconName: "edit-delete"
						label: "Delete"
						labelColor: "#ff6b6b"
						enabled: missionPlanSelector.count > 0
						onClicked: dockRoot.deleteMissionDraft(dockRoot.selectedSavedMissionName())
					}
				}
			}
		}

		ButtonGroup {
			id: waypointInspector
			z: 5
			anchors.left: missionOverlay.right
			anchors.bottom: parent.bottom
			anchors.margins: Style.overlayMargin
			title: dockRoot.selectedMissionItem() ? "WAYPOINT " + (dockRoot.selectedMissionItemIndex + 1) : "WAYPOINT"
			horizontal: true
			visible: dockRoot.mapMode === 1 && dockRoot.selectedMissionItem() !== null

			IconButton {
				iconName: "configure"
				label: "Config"
				checkable: true
				checked: dockRoot.waypointConfigOpen
				onClicked: dockRoot.waypointConfigOpen = checked
			}
			IconButton {
				iconName: dockRoot.selectedMissionItem() && dockRoot.selectedMissionItem().flyThrough ? "media-seek-forward" : "media-playback-pause"
				label: dockRoot.selectedMissionItem() && dockRoot.selectedMissionItem().flyThrough ? "Fly through" : "Stop at WP"
				checkable: true
				checked: dockRoot.selectedMissionItem() ? dockRoot.selectedMissionItem().flyThrough : false
				onClicked: dockRoot.setSelectedMissionFlyThrough(checked)
			}
			IconButton {
				iconName: "edit-delete"
				label: "Delete WP"
				labelColor: "#ff6b6b"
				onClicked: dockRoot.removeSelectedMissionWaypoint()
			}
		}

		ButtonGroup {
			id: waypointConfigPanel
			z: 6
			anchors.left: waypointInspector.left
			anchors.bottom: waypointInspector.top
			anchors.bottomMargin: Style.sectionSpacing
			title: "WP OPTIONS"
			visible: waypointInspector.visible && dockRoot.waypointConfigOpen

			Column {
				spacing: 2

				MissionOptionEditor {
					title: "Speed"
					suffix: "m/s"
					value: dockRoot.selectedMissionItem() ? dockRoot.selectedMissionItem().speed : 0
					optionEnabled: dockRoot.selectedMissionItem() ? dockRoot.selectedMissionItem().speedEnabled : false
					minimumValue: 0.5
					maximumValue: 100
					decimals: 1
					onOptionEnabledEdited: function (enabled) {
						dockRoot.setSelectedMissionOptionEnabled("speedEnabled", enabled);
					}
					onValueEdited: function (value) {
						dockRoot.setSelectedMissionSpeed(value);
					}
				}
				MissionOptionEditor {
					title: "Radius"
					suffix: "m"
					value: dockRoot.selectedMissionItem() ? dockRoot.selectedMissionItem().acceptanceRadius : 0
					optionEnabled: dockRoot.selectedMissionItem() ? dockRoot.selectedMissionItem().acceptanceRadiusEnabled : false
					minimumValue: 0.5
					maximumValue: 200
					decimals: 1
					onOptionEnabledEdited: function (enabled) {
						dockRoot.setSelectedMissionOptionEnabled("acceptanceRadiusEnabled", enabled);
					}
					onValueEdited: function (value) {
						dockRoot.setSelectedMissionAcceptanceRadius(value);
					}
				}
				MissionOptionEditor {
					title: "Loiter"
					suffix: "s"
					value: dockRoot.selectedMissionItem() ? dockRoot.selectedMissionItem().loiter : 0
					optionEnabled: dockRoot.selectedMissionItem() ? dockRoot.selectedMissionItem().loiterEnabled : false
					minimumValue: 0
					maximumValue: 3600
					decimals: 0
					onOptionEnabledEdited: function (enabled) {
						dockRoot.setSelectedMissionOptionEnabled("loiterEnabled", enabled);
					}
					onValueEdited: function (value) {
						dockRoot.setSelectedMissionLoiter(value);
					}
				}
			}
		}

		Row {
			id: topRightOverlay
			z: 5
			anchors.top: parent.top
			anchors.right: parent.right
			anchors.margins: Style.overlayMargin
			spacing: Style.sectionSpacing

			Column {
				spacing: 4
				anchors.top: parent.top

				Repeater {
					model: SwarmManager.droneList
					delegate: DroneStatusBadge {
						required property int index
						required property var modelData

						droneName: modelData.droneName
						connected: modelData.connected
						flightMode: modelData.flightMode
						armed: modelData.armed
						altitude: modelData.altitude
						batteryPercent: modelData.battery
						selected: index === dockRoot.selectedDroneIndex
						onClicked: SwarmManager.selectDrone(dockRoot.selectedDroneIndex === index ? -1 : index)
					}
				}
			}

			ButtonGroup {
				title: "ACTIONS"
				horizontal: true

				IconButton {
					property bool _armed: dockRoot.selectedDrone ? dockRoot.selectedDrone.armed : false
					property bool _connected: dockRoot.selectedDrone ? dockRoot.selectedDrone.connected : false
					iconName: _armed ? "security-high" : "security-low"
					label: _armed ? "Disarm" : "Arm"
					labelColor: _armed ? "#ff6b6b" : "#6bffb8"
					highlighted: _armed
					enabled: _connected && (!_armed || !(dockRoot.selectedDrone && dockRoot.selectedDrone.inFlight))
					onClicked: if (dockRoot.selectedDrone)
						dockRoot.selectedDrone.armed ? dockRoot.selectedDrone.disarm() : dockRoot.selectedDrone.arm()
				}
				IconButton {
					iconName: "arrow-up-double"
					label: "Takeoff"
					labelColor: "#6bffb8"
					enabled: dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.selectedDrone.armed && !dockRoot.selectedDrone.inFlight
					onClicked: if (dockRoot.selectedDrone)
						dockRoot.selectedDrone.takeoff()
				}
				IconButton {
					iconName: "arrow-down-double"
					label: "Land"
					labelColor: "#ffd06b"
					enabled: dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.selectedDrone.inFlight
					onClicked: if (dockRoot.selectedDrone)
						dockRoot.selectedDrone.land()
				}
				IconButton {
					iconName: "go-home-large"
					label: "RTH"
					labelColor: "#6bb8ff"
					enabled: dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.selectedDrone.inFlight
					onClicked: if (dockRoot.selectedDrone)
						dockRoot.selectedDrone.rth()
				}
			}

			ButtonGroup {
				id: mapSettings
				title: "MAP"
				horizontal: true

				property bool is3d: false
				property bool isDark: true
				property bool isSatellite: false

				IconButton {
					iconName: mapSettings.is3d ? "map-gnomonic" : "map-flat"
					label: mapSettings.is3d ? "3D" : "2D"
					checkable: true
					checked: mapSettings.is3d
					onClicked: mapSettings.is3d = !mapSettings.is3d
				}
				IconButton {
					enabled: !mapSettings.isSatellite
					opacity: enabled ? 1.0 : 0.4
					iconName: mapSettings.isDark ? "weather-clear-night-symbolic" : "contrast"
					label: mapSettings.isDark ? "Dark" : "Light"
					checkable: true
					checked: mapSettings.isDark
					onClicked: mapSettings.isDark = !mapSettings.isDark
				}
				IconButton {
					iconName: mapSettings.isSatellite ? "kstars_satellites" : "map-globe"
					label: mapSettings.isSatellite ? "Sat" : "Street"
					checkable: true
					checked: mapSettings.isSatellite
					onClicked: mapSettings.isSatellite = !mapSettings.isSatellite
				}
			}
		}

		AltitudeTape {
			id: altTape
			enabled: dockRoot.selectedDroneIndex >= 0 || (dockRoot.mapMode === 1 && dockRoot.selectedMissionItem() !== null)
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			altitude: dockRoot.mapMode === 1 && dockRoot.selectedMissionItem() ? dockRoot.selectedMissionItem().altitude : (dockRoot.selectedDrone ? dockRoot.selectedDrone.altitude : 0)
			darkMode: mapSettings.isDark
			liveEdit: dockRoot.mapMode === 1 && dockRoot.selectedMissionItem() !== null
			minimumAltitude: liveEdit ? 5 : 0
			z: 1
			onTargetEdited: function (target) {
				dockRoot.setSelectedMissionAltitude(target);
			}
			onTargetConfirmed: function (target) {
				if (!altTape.liveEdit && dockRoot.selectedDrone) {
					dockRoot._targetStore[String(dockRoot.selectedDrone.droneUid)] = {
						"alt": target,
						"locked": true
					};
					dockRoot.selectedDrone.setAltitude(target);
				}
			}
			onTargetReset: {
				if (!altTape.liveEdit && dockRoot.selectedDrone)
					dockRoot._targetStore[String(dockRoot.selectedDrone.droneUid)] = {
						"alt": 0,
						"locked": false
					};
			}
		}
	}
}
