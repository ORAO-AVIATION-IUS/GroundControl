pragma ComponentBehavior: Bound

import Agc.Components
import Agc.Mavlink
import Agc.Style
import QtPositioning
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: dockRoot
	uniqueName: "mapPanel"
	title: qsTr("Map")

	property int mapMode: 0
	property string activePlanningTool: "edit"
	property string activeTrackingTool: ""
	readonly property var missionPlan: selectedDrone && selectedDrone.missionPlan ? selectedDrone.missionPlan : fallbackMissionPlan
	readonly property var missionItems: missionPlan.items
	readonly property int selectedMissionItemIndex: missionPlan.selectedIndex
	readonly property int missionRevision: missionPlan.revision
	// Reactive snapshot of the selected waypoint. selectedItem() returns a
	// QVariant snapshot, so a plain selectedMissionItem() call in a binding
	// can't be tracked; depending on the index/revision here makes consumers
	// (e.g. the altitude tape) update when the selection or plan changes.
	readonly property var selectedMissionItemData: {
		void selectedMissionItemIndex;
		void missionRevision;
		return missionPlan.selectedItem();
	}
	readonly property bool returnHomeAfterMission: missionPlan.returnHomeAfterMission
	readonly property bool landAfterMission: missionPlan.landAfterMission
	readonly property bool missionUploaded: selectedDrone ? selectedDrone.missionUploaded : false
	readonly property bool missionDirty: selectedDrone ? selectedDrone.missionDirty : false
	readonly property bool missionBusy: selectedDrone ? selectedDrone.missionBusy : false
	readonly property bool missionRunning: selectedDrone ? selectedDrone.missionRunning : false
	readonly property bool missionPaused: selectedDrone ? selectedDrone.missionPaused : false
	property bool waypointConfigOpen: false
	property bool missionLibraryOpen: false
	property string missionDraftName: "Mission"
	property int missionRenderRevision: 0
	property bool missionConfirmOpen: false
	property string missionConfirmAction: ""
	property int missionConfirmDroneUid: -1
	readonly property string missionBusyText: selectedDrone ? selectedDrone.missionBusyText : ""
	readonly property string missionErrorText: localMissionError !== "" ? localMissionError : (selectedDrone ? selectedDrone.missionErrorText : "")
	property string localMissionError: ""
	readonly property var guided: selectedDrone && selectedDrone.guided ? selectedDrone.guided : fallbackGuided
	readonly property double localHomeLatitude: guided.localHomeLatitude
	readonly property double localHomeLongitude: guided.localHomeLongitude
	readonly property double localHomeAltitude: guided.localHomeAltitude
	readonly property bool localHomeValid: guided.localHomeValid
	readonly property bool goTargetValid: guided.goTargetValid
	readonly property double goTargetLatitude: guided.goTargetLatitude
	readonly property double goTargetLongitude: guided.goTargetLongitude
	readonly property double goTargetAltitude: guided.goTargetAltitude
	readonly property double goTargetHeading: guided.goTargetHeading
	readonly property bool lookTargetValid: guided.lookTargetValid
	readonly property double lookTargetLatitude: guided.lookTargetLatitude
	readonly property double lookTargetLongitude: guided.lookTargetLongitude
	readonly property double lookTargetHeading: guided.lookTargetHeading
	readonly property bool flyPromptOpen: guided.flyPromptOpen
	readonly property string flyPromptKind: guided.flyPromptKind
	readonly property bool mapContextOpen: guided.mapContextOpen
	readonly property var mapContextCoordinate: QtPositioning.coordinate(guided.mapContextLatitude, guided.mapContextLongitude)
	readonly property real mapContextX: guided.mapContextX
	readonly property real mapContextY: guided.mapContextY

	MissionPlanStore {
		id: missionStore
	}

	FileDialog {
		id: missionExportDialog
		title: qsTr("Export mission plan")
		fileMode: FileDialog.SaveFile
		nameFilters: [qsTr("Mission JSON (*.json)")]
		defaultSuffix: "json"
		onAccepted: {
			if (!missionStore.exportMission(selectedFile, dockRoot.missionDraftName, dockRoot.missionPlan)) {
				dockRoot.setMissionError(missionStore.errorText);
				return;
			}
			dockRoot.localMissionError = "";
			if (dockRoot.selectedDrone)
				dockRoot.selectedDrone.log(dockRoot.selectedDrone.droneName, qsTr("Mission exported"), "info");
		}
	}

	FileDialog {
		id: missionImportDialog
		title: qsTr("Import mission plan")
		fileMode: FileDialog.OpenFile
		nameFilters: [qsTr("Mission JSON (*.json)")]
		onAccepted: {
			if (!missionStore.importMission(selectedFile, dockRoot.missionPlan)) {
				dockRoot.setMissionError(missionStore.errorText);
				return;
			}
			dockRoot.missionPlan.selectedIndex = dockRoot.missionItems.length > 0 && dockRoot.mapMode === 1 ? 0 : -1;
			dockRoot.missionDraftName = qsTr("Imported Mission");
			dockRoot.localMissionError = "";
		}
	}

	MissionPlanModel {
		id: fallbackMissionPlan
	}

	GuidedTargetModel {
		id: fallbackGuided
	}

	// Once the user explicitly deselects a drone, stop auto-follow from
	// immediately reselecting the lone connected drone on the next telemetry
	// tick (same suppression as panning the map).
	Connections {
		target: SwarmManager
		function onSelectedDroneIndexChanged() {
			if (SwarmManager.selectedDroneIndex === -1)
				dockRoot.autoFollowSuppressed = true;
		}
	}

	property var _targetStore: ({})
	property bool followSelectedDrone: false
	property bool autoFollowSuppressed: false

	readonly property int selectedDroneIndex: SwarmManager.selectedDroneIndex
	readonly property var selectedDrone: SwarmManager.selectedDrone
	readonly property alias hoveredCoordinate: mapView.hoveredCoordinate

	onMapModeChanged: {
		if (mapMode !== 1) {
			missionPlan.selectedIndex = -1;
			waypointConfigOpen = false;
		}
		if (mapMode !== 2) {
			guided.closePrompt();
			guided.closeMapContext();
		}
	}

	onSelectedDroneChanged: {
		if (!selectedDrone || missionConfirmDroneUid !== selectedDrone.droneUid)
			missionConfirmOpen = false;
		if (selectedDrone) {
			var entry = _targetStore[String(selectedDrone.droneUid)];
			if (entry && entry.locked)
				altTape.setTarget(entry.alt);
			else
				altTape.clearTarget();
		} else {
			altTape.clearTarget();
		}
		localMissionError = "";
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

	function connectedDroneIndexes() {
		const indexes = [];
		for (let i = 0; i < SwarmManager.droneList.length; ++i) {
			const drone = SwarmManager.droneList[i];
			if (drone && drone.connected)
				indexes.push(i);
		}
		return indexes;
	}

	function droneMissionColor(index) {
		return Style.missionColor(index);
	}

	function visibleMissionPlans() {
		void missionRenderRevision;
		const plans = [];
		for (let i = 0; i < SwarmManager.droneList.length; ++i) {
			const drone = SwarmManager.droneList[i];
			const plan = drone && drone.missionPlan ? drone.missionPlan : null;
			const items = plan && plan.items ? plan.items : [];
			if (!drone || !plan || items.length === 0)
				continue;
			const selected = selectedDrone && drone.droneUid === selectedDrone.droneUid;
			const useLocalHome = selected && !drone.homeValid && localHomeValid;
			plans.push({
				"droneUid": drone.droneUid,
				"droneName": drone.droneName,
				"items": items,
				"selected": selected,
				"selectedIndex": selected && mapMode === 1 ? plan.selectedIndex : -1,
				"currentIndex": drone.wpCurrent,
				"color": droneMissionColor(i),
				"returnHomeAfterMission": plan.returnHomeAfterMission,
				"homeLatitude": drone.homeValid ? drone.homeLatitude : localHomeLatitude,
				"homeLongitude": drone.homeValid ? drone.homeLongitude : localHomeLongitude,
				"homeValid": drone.homeValid || useLocalHome,
				"revision": plan.revision,
				"signature": plan.signature
			});
		}
		return plans;
	}

	function missionInsertTargetsForPlan(plan) {
		const targets = [];
		const items = plan && plan.items ? plan.items : [];
		if (!plan || !plan.selected || mapMode !== 1 || items.length < 2)
			return targets;
		for (let i = 0; i < items.length - 1; ++i) {
			const a = QtPositioning.coordinate(items[i].latitude, items[i].longitude);
			const b = QtPositioning.coordinate(items[i + 1].latitude, items[i + 1].longitude);
			const mid = a.atDistanceAndAzimuth(a.distanceTo(b) * 0.5, a.azimuthTo(b));
			targets.push({
				"id": "mission-insert-" + plan.droneUid + "-" + i,
				"type": "MissionInsertHandle",
				"droneUid": plan.droneUid,
				"latitude": mid.latitude,
				"longitude": mid.longitude,
				"altitude": 0,
				"selected": false,
				"editable": true,
				"draggable": false,
				"segmentIndex": i,
				"fill": "#ffffff",
				"stroke": plan.color,
				"radius": 4,
				"strokeWidth": 1.5,
				"opacity": 0.58
			});
		}
		return targets;
	}

	function mapTargets() {
		const targets = [];
		const plans = visibleMissionPlans();
		for (let p = 0; p < plans.length; ++p) {
			const plan = plans[p];
			const items = plan.items || [];
			for (let i = 0; i < items.length; ++i) {
				const item = items[i];
				if (!item)
					continue;
				const selected = plan.selected && mapMode === 1 && i === plan.selectedIndex;
				const current = plan.currentIndex > 0 && i === plan.currentIndex - 1;
				targets.push({
					"id": "mission-waypoint-" + plan.droneUid + "-" + i,
					"type": "MissionWaypoint",
					"droneUid": plan.droneUid,
					"latitude": item.latitude,
					"longitude": item.longitude,
					"altitude": item.altitude || 0,
					"heading": item.heading || 0,
					"selected": selected,
					"editable": plan.selected,
					"draggable": plan.selected && mapMode === 1,
					"missionItemIndex": i,
					"fill": current ? "#ffaa00" : (selected ? "#ffaa00" : plan.color),
					"stroke": "#ffffff",
					"radius": plan.selected ? (selected ? 8 : 6) : 4,
					"strokeWidth": plan.selected ? (selected ? 3 : 2) : 1,
					"opacity": plan.selected ? (mapSettings.is3d ? 0.55 : 0.95) : 0.46
				});
			}
			const insertTargets = missionInsertTargetsForPlan(plan);
			for (let j = 0; j < insertTargets.length; ++j)
				targets.push(insertTargets[j]);
		}
		if (mapMode === 2 && selectedDrone) {
			if (goTargetValid) {
				targets.push({
					"id": "go-" + selectedDrone.droneUid,
					"type": "GoTarget",
					"droneUid": selectedDrone.droneUid,
					"latitude": goTargetLatitude,
					"longitude": goTargetLongitude,
					"altitude": goTargetAltitude,
					"heading": goTargetHeading,
					"selected": flyPromptKind === "go",
					"editable": true,
					"draggable": true,
					"fill": "#5a9aef",
					"stroke": "#ffffff",
					"radius": 8,
					"strokeWidth": 2,
					"opacity": 0.95
				});
			}
			if (lookTargetValid) {
				targets.push({
					"id": "look-" + selectedDrone.droneUid,
					"type": "LookTarget",
					"droneUid": selectedDrone.droneUid,
					"latitude": lookTargetLatitude,
					"longitude": lookTargetLongitude,
					"heading": lookTargetHeading,
					"selected": flyPromptKind === "look",
					"editable": true,
					"draggable": true,
					"fill": "#ffb347",
					"stroke": "#1c1f26",
					"radius": 7,
					"strokeWidth": 2,
					"opacity": 0.95
				});
			}
			if ((selectedDrone.homeValid || localHomeValid)) {
				targets.push({
					"id": "home-" + selectedDrone.droneUid,
					"type": "HomeTarget",
					"droneUid": selectedDrone.droneUid,
					"latitude": selectedDrone.homeValid ? selectedDrone.homeLatitude : localHomeLatitude,
					"longitude": selectedDrone.homeValid ? selectedDrone.homeLongitude : localHomeLongitude,
					"altitude": selectedDrone.homeValid ? selectedDrone.homeAltitude : localHomeAltitude,
					"selected": flyPromptKind === "home",
					"editable": true,
					"draggable": true,
					"fill": "#6bffb8",
					"stroke": "#ffffff",
					"radius": 8,
					"strokeWidth": 2,
					"opacity": 0.95
				});
			}
		}
		return targets;
	}

	function autoFollowSingleConnectedDrone() {
		if (autoFollowSuppressed)
			return;
		const indexes = connectedDroneIndexes();
		if (indexes.length !== 1)
			return;
		const index = indexes[0];
		const drone = SwarmManager.droneList[index];
		if (!drone || !hasPosition(drone))
			return;
		if (selectedDroneIndex !== index)
			SwarmManager.selectDrone(index);
		followSelectedDrone = true;
		followSelected();
	}

	function selectedMissionItem() {
		return missionPlan.selectedItem();
	}

	function missionSignatureFor(items, rtl) {
		return JSON.stringify({
			"returnHomeAfterMission": rtl === true,
			"items": items || []
		});
	}

	function currentMissionSignature() {
		return missionPlan.signature;
	}

	function markMissionChanged() {
		localMissionError = "";
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
		if (missionDirty)
			return "DIRTY";
		if (missionUploaded)
			return "UPLOADED";
		return "DRAFT";
	}

	function setMissionError(message) {
		localMissionError = message;
	}

	function handlePlanMapClick(coordinate) {
		if (activePlanningTool === "waypoint")
			addMissionWaypoint(coordinate);
	}

	function normalizeHeading(heading) {
		return ((heading % 360) + 360) % 360;
	}

	function showMapContext(coordinate, screenPoint) {
		if (mapMode !== 2 || !coordinate || !coordinate.isValid)
			return;
		guided.setMapContext(coordinate.latitude, coordinate.longitude, screenPoint.x, screenPoint.y);
	}

	function targetHeading(coordinate) {
		if (!coordinate || !coordinate.isValid || !selectedDrone || !hasPosition(selectedDrone))
			return 0;
		return normalizeHeading(QtPositioning.coordinate(selectedDrone.latitude, selectedDrone.longitude).azimuthTo(coordinate));
	}

	function snapshotTarget(kind) {
		guided.snapshotTarget(kind);
	}

	function applyTarget(kind, coordinate) {
		if (!coordinate || !coordinate.isValid || !selectedDrone || !hasPosition(selectedDrone))
			return;
		if (kind === "go") {
			const altitude = goTargetValid ? goTargetAltitude : selectedDrone.altitude;
			guided.setGoTarget(coordinate.latitude, coordinate.longitude, altitude, targetHeading(coordinate));
		} else if (kind === "look") {
			guided.setLookTarget(coordinate.latitude, coordinate.longitude, targetHeading(coordinate));
		}
	}

	function cancelPendingFlyEdit(nextKind) {
		if (flyPromptOpen && flyPromptKind !== nextKind)
			closeFlyPrompt();
	}

	function requestFlyAction(kind, coordinate) {
		cancelPendingFlyEdit(kind);
		snapshotTarget(kind);
		applyTarget(kind, coordinate);
		guided.openPrompt(kind);
		guided.closeMapContext();
	}

	function beginFlyTargetEdit(kind) {
		cancelPendingFlyEdit(kind);
		if (kind !== "home")
			snapshotTarget(kind);
	}

	function moveFlyTarget(kind, coordinate) {
		if (kind === "home") {
			setHomePoint(coordinate, false);
			return;
		}
		applyTarget(kind, coordinate);
	}

	function openFlyTargetPrompt(kind) {
		if (kind === "home") {
			if (localHomeValid)
				setHomePoint(QtPositioning.coordinate(localHomeLatitude, localHomeLongitude), true);
			guided.closePrompt();
			return;
		}
		cancelPendingFlyEdit(kind);
		guided.openPrompt(kind);
		guided.closeMapContext();
	}

	function restoreFlyEditSnapshot() {
		guided.restoreSnapshot();
	}

	function closeFlyPrompt() {
		restoreFlyEditSnapshot();
		guided.closePrompt();
	}

	function deleteFlyPromptTarget() {
		guided.clearTarget(flyPromptKind);
		guided.closePrompt();
	}

	function confirmFlyPrompt() {
		if (!selectedDrone || !selectedDrone.connected)
			return;
		if (flyPromptKind === "go" && goTargetValid)
			selectedDrone.goToLocation(goTargetLatitude, goTargetLongitude, goTargetAltitude, goTargetHeading);
		else if (flyPromptKind === "look" && lookTargetValid && hasPosition(selectedDrone))
			selectedDrone.goToLocation(selectedDrone.latitude, selectedDrone.longitude, selectedDrone.altitude, lookTargetHeading);
		guided.closePrompt();
		guided.clearSnapshot();
	}

	function focusFlyTarget(kind) {
		if (kind === "go" && goTargetValid)
			mapView.centerOn(QtPositioning.coordinate(goTargetLatitude, goTargetLongitude));
		else if (kind === "look" && lookTargetValid)
			mapView.centerOn(QtPositioning.coordinate(lookTargetLatitude, lookTargetLongitude));
		else if (kind === "home" && ((selectedDrone && selectedDrone.homeValid) || localHomeValid))
			mapView.centerOn(QtPositioning.coordinate(selectedDrone && selectedDrone.homeValid ? selectedDrone.homeLatitude : localHomeLatitude, selectedDrone && selectedDrone.homeValid ? selectedDrone.homeLongitude : localHomeLongitude));
	}

	function homeAltitudeForSetHome() {
		if (selectedDrone && selectedDrone.homeValid)
			return selectedDrone.homeAltitude;
		if (localHomeValid)
			return localHomeAltitude;
		if (selectedDrone)
			return selectedDrone.altitudeMsl - selectedDrone.altitude;
		return 0;
	}

	function setHomePoint(coordinate, sendToDrone) {
		if (!coordinate || !coordinate.isValid)
			return;
		const altitude = homeAltitudeForSetHome();
		guided.setLocalHome(coordinate.latitude, coordinate.longitude, altitude);
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
		missionPlan.addWaypoint(coordinate.latitude, coordinate.longitude);
		markMissionChanged();
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
		missionPlan.insertWaypointAtSegment(segmentIndex, coordinate.latitude, coordinate.longitude);
		markMissionChanged();
	}

	function moveMissionWaypoint(index, coordinate) {
		if (index < 0 || index >= missionItems.length || !coordinate || !coordinate.isValid)
			return;
		missionPlan.moveWaypoint(index, coordinate.latitude, coordinate.longitude);
		markMissionChanged();
	}

	function setSelectedMissionAltitude(altitude) {
		missionPlan.setSelectedField("altitude", altitude, 5);
		markMissionChanged();
	}

	function setSelectedMissionSpeed(speed) {
		missionPlan.setSelectedField("speed", speed, 0.5);
		markMissionChanged();
	}

	function setSelectedMissionAcceptanceRadius(radius) {
		missionPlan.setSelectedField("acceptanceRadius", radius, 0.5);
		markMissionChanged();
	}

	function setSelectedMissionLoiter(loiter) {
		missionPlan.setSelectedField("loiter", loiter, 0);
		markMissionChanged();
	}

	function setSelectedMissionHeading(heading) {
		missionPlan.setSelectedField("heading", normalizeHeading(heading), 0);
		markMissionChanged();
	}

	function setSelectedMissionOptionEnabled(fieldName, enabled) {
		missionPlan.setSelectedOptionEnabled(fieldName, enabled);
		markMissionChanged();
	}

	function setSelectedMissionFlyThrough(flyThrough) {
		missionPlan.setSelectedFlyThrough(flyThrough);
		markMissionChanged();
	}

	function removeSelectedMissionWaypoint() {
		missionPlan.removeSelectedWaypoint();
		markMissionChanged();
	}

	function clearLocalMission() {
		missionPlan.clear();
		waypointConfigOpen = false;
		localMissionError = "";
	}

	function missionDistanceMeters() {
		return missionPlan.distanceMeters;
	}

	function missionDistanceText() {
		return missionPlan.distanceText();
	}

	function savedMissionNames() {
		void missionStore.revision;
		return missionStore.missionNames;
	}

	function selectedSavedMissionName() {
		const names = savedMissionNames();
		return names.length > 0 ? names[missionPlanSelector.currentIndex] : "";
	}

	function saveMissionDraft(name) {
		const trimmedName = String(name || "").trim();
		if (!missionStore.saveMission(trimmedName, missionPlan)) {
			setMissionError(missionStore.errorText);
			return;
		}
		missionDraftName = trimmedName;
		localMissionError = "";
		if (selectedDrone)
			selectedDrone.log(selectedDrone.droneName, qsTr("Mission draft saved: %1").arg(trimmedName), "info");
	}

	function loadMissionDraft(name) {
		const trimmedName = String(name || "").trim();
		if (trimmedName === "") {
			setMissionError(qsTr("Select a saved mission draft"));
			return;
		}
		if (!missionStore.loadMission(trimmedName, missionPlan)) {
			setMissionError(missionStore.errorText);
			return;
		}
		missionPlan.selectedIndex = missionItems.length > 0 && mapMode === 1 ? 0 : -1;
		missionDraftName = trimmedName;
		localMissionError = "";
	}

	function deleteMissionDraft(name) {
		const trimmedName = String(name || "").trim();
		if (!missionStore.deleteMission(trimmedName) && missionStore.errorText !== "")
			setMissionError(missionStore.errorText);
	}

	function validateMissionDraft() {
		if (!selectedDrone)
			return qsTr("Select a drone before uploading");
		if (!selectedDrone.connected)
			return qsTr("Selected drone is not connected");
		return missionPlan.validateForUpload();
	}

	function missionConfirmText() {
		if (!selectedDrone || !missionConfirmOpen)
			return "";
		const actionText = missionConfirmAction === "start" ? qsTr("START") : qsTr("CLEAR");
		return qsTr("%1 %2  UID %3  %4 WP  %5").arg(actionText).arg(selectedDrone.droneName).arg(selectedDrone.droneUid).arg(missionItems.length).arg(missionStatusText());
	}

	function openMissionConfirmation(action) {
		if (!selectedDrone)
			return;
		missionConfirmAction = action;
		missionConfirmDroneUid = selectedDrone.droneUid;
		missionConfirmOpen = true;
	}

	function cancelMissionConfirmation() {
		missionConfirmOpen = false;
		missionConfirmAction = "";
		missionConfirmDroneUid = -1;
	}

	function confirmMissionCommand() {
		if (!selectedDrone || selectedDrone.droneUid !== missionConfirmDroneUid) {
			setMissionError(qsTr("Selected drone changed; command cancelled"));
			cancelMissionConfirmation();
			return;
		}
		const action = missionConfirmAction;
		cancelMissionConfirmation();
		localMissionError = "";
		if (action === "start") {
			// A finished mission must be restarted (reset to WP 0), otherwise
			// the vehicle reports "No valid mission available" and loiters.
			if (selectedDrone.missionFinished)
				selectedDrone.restartMission();
			else
				selectedDrone.startMission();
		} else if (action === "clear") {
			selectedDrone.clearMission();
		}
	}

	function requestMissionUpload() {
		const error = validateMissionDraft();
		if (error !== "") {
			setMissionError(error);
			if (selectedDrone)
				selectedDrone.log(selectedDrone.droneName, error, "warning");
			return;
		}
		localMissionError = "";
		selectedDrone.uploadMission(missionItems, returnHomeAfterMission, landAfterMission);
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
		openMissionConfirmation("start");
	}

	function requestMissionPause() {
		if (!selectedDrone || !selectedDrone.connected)
			return;
		localMissionError = "";
		selectedDrone.pauseMission();
	}

	function requestMissionClear() {
		if (selectedDrone && selectedDrone.connected) {
			openMissionConfirmation("clear");
			return;
		}
		clearLocalMission();
	}

	function requestMissionDownload() {
		if (!selectedDrone || !selectedDrone.connected) {
			setMissionError(qsTr("Selected drone is not connected"));
			return;
		}
		localMissionError = "";
		selectedDrone.downloadMission();
	}

	function handleMissionUploadFinished(drone, success, message) {
		void drone;
		if (success)
			localMissionError = "";
		else
			localMissionError = message;
	}

	function handleMissionStartFinished(drone, success, message) {
		void drone;
		if (success)
			localMissionError = "";
		else
			localMissionError = message;
	}

	function handleMissionPauseFinished(drone, success, message) {
		void drone;
		if (success)
			localMissionError = "";
		else
			localMissionError = message;
	}

	function handleMissionClearFinished(drone, success, message) {
		if (!success) {
			localMissionError = message;
			return;
		}
		localMissionError = "";
		if (selectedDrone && selectedDrone.droneUid === drone.droneUid)
			clearLocalMission();
	}

	function handleMissionDownloadFinished(drone, success, message, downloadedMissionItems, returnToLaunchAfterMission) {
		if (!success) {
			localMissionError = message;
			return;
		}
		localMissionError = "";
		if (selectedDrone && selectedDrone.droneUid === drone.droneUid) {
			missionPlan.items = downloadedMissionItems;
			missionPlan.selectedIndex = missionItems.length > 0 ? 0 : -1;
			missionPlan.returnHomeAfterMission = returnToLaunchAfterMission;
		}
	}

	Shortcut {
		sequences: [StandardKey.Cancel]
		onActivated: {
			dockRoot.guided.closeMapContext();
			if (dockRoot.flyPromptOpen)
				dockRoot.closeFlyPrompt();
		}
	}

	Item {
		anchors.fill: parent

		Repeater {
			model: SwarmManager.droneList
			delegate: Item {
				id: followDelegate

				required property var modelData

				Connections {
					target: followDelegate.modelData

					function onConnectedChanged() {
						dockRoot.autoFollowSingleConnectedDrone();
					}

					function onMissionUploadFinished(success, message) {
						dockRoot.handleMissionUploadFinished(followDelegate.modelData, success, message);
					}

					function onMissionStartFinished(success, message) {
						dockRoot.handleMissionStartFinished(followDelegate.modelData, success, message);
					}

					function onMissionPauseFinished(success, message) {
						dockRoot.handleMissionPauseFinished(followDelegate.modelData, success, message);
					}

					function onMissionClearFinished(success, message) {
						dockRoot.handleMissionClearFinished(followDelegate.modelData, success, message);
					}

					function onMissionDownloadFinished(success, message, missionItems, returnToLaunchAfterMission) {
						dockRoot.handleMissionDownloadFinished(followDelegate.modelData, success, message, missionItems, returnToLaunchAfterMission);
					}

					function onLatitudeChanged() {
						if (dockRoot.followSelectedDrone && followDelegate.modelData === dockRoot.selectedDrone)
							dockRoot.followSelected();
						else
							dockRoot.autoFollowSingleConnectedDrone();
					}

					function onLongitudeChanged() {
						if (dockRoot.followSelectedDrone && followDelegate.modelData === dockRoot.selectedDrone)
							dockRoot.followSelected();
						else
							dockRoot.autoFollowSingleConnectedDrone();
					}

					function onWpCurrentChanged() {
						dockRoot.missionRenderRevision += 1;
					}

					function onHomeChanged() {
						dockRoot.missionRenderRevision += 1;
					}
				}

				Connections {
					target: followDelegate.modelData ? followDelegate.modelData.missionPlan : null

					function onRevisionChanged() {
						dockRoot.missionRenderRevision += 1;
					}

					function onSelectedIndexChanged() {
						dockRoot.missionRenderRevision += 1;
					}

					function onReturnHomeAfterMissionChanged() {
						dockRoot.missionRenderRevision += 1;
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
			visibleMissionPlans: dockRoot.visibleMissionPlans()
			mapTargets: dockRoot.mapTargets()
			selectedMissionItemIndex: dockRoot.mapMode === 1 ? dockRoot.selectedMissionItemIndex : -1
			currentMissionItemIndex: dockRoot.selectedDrone ? dockRoot.selectedDrone.wpCurrent : 0
			homeLatitude: dockRoot.selectedDrone && dockRoot.selectedDrone.homeValid ? dockRoot.selectedDrone.homeLatitude : dockRoot.localHomeLatitude
			homeLongitude: dockRoot.selectedDrone && dockRoot.selectedDrone.homeValid ? dockRoot.selectedDrone.homeLongitude : dockRoot.localHomeLongitude
			homeValid: dockRoot.selectedDrone && dockRoot.selectedDrone.homeValid ? true : dockRoot.localHomeValid
			returnHomeAfterMission: dockRoot.returnHomeAfterMission
			goTargetValid: dockRoot.mapMode === 2 && dockRoot.goTargetValid
			goTargetLatitude: dockRoot.goTargetLatitude
			goTargetLongitude: dockRoot.goTargetLongitude
			goTargetAltitude: dockRoot.goTargetAltitude
			goTargetHeading: dockRoot.goTargetHeading
			lookTargetValid: dockRoot.mapMode === 2 && dockRoot.lookTargetValid
			lookTargetLatitude: dockRoot.lookTargetLatitude
			lookTargetLongitude: dockRoot.lookTargetLongitude
			lookTargetHeading: dockRoot.lookTargetHeading
			flyTargetDroneLatitude: dockRoot.selectedDrone ? dockRoot.selectedDrone.latitude : 0
			flyTargetDroneLongitude: dockRoot.selectedDrone ? dockRoot.selectedDrone.longitude : 0
			missionRevision: dockRoot.missionRevision
			onDroneClicked: function (droneUid) {
				dockRoot.selectDroneByUid(droneUid);
			}
			onMissionMapClicked: function (coordinate) {
				dockRoot.handlePlanMapClick(coordinate);
			}
			onMissionItemClicked: function (index) {
				dockRoot.missionPlan.selectedIndex = index;
			}
			onMissionPlanItemClicked: function (droneUid, index) {
				const drone = SwarmManager.droneByUid(droneUid);
				if (!drone || !drone.missionPlan)
					return;
				dockRoot.selectDroneByUid(droneUid);
				drone.missionPlan.selectedIndex = index;
			}
			onMissionItemMoved: function (index, coordinate) {
				dockRoot.moveMissionWaypoint(index, coordinate);
			}
			onMissionSegmentInsertRequested: function (segmentIndex, coordinate) {
				dockRoot.insertMissionWaypointAtSegment(segmentIndex, coordinate);
			}
			onHomeMapClicked: function (coordinate) {
				dockRoot.setHomePoint(coordinate, true);
			}
			onMapContextRequested: function (coordinate, screenPoint) {
				dockRoot.showMapContext(coordinate, screenPoint);
			}
			onMapInteractionStarted: dockRoot.guided.closeMapContext()
			onFlyTargetEditStarted: function (targetKind) {
				dockRoot.beginFlyTargetEdit(targetKind);
			}
			onFlyTargetMoved: function (targetKind, coordinate) {
				dockRoot.moveFlyTarget(targetKind, coordinate);
			}
			onFlyTargetClicked: function (targetKind) {
				dockRoot.openFlyTargetPrompt(targetKind);
			}
			onUserMovedMap: {
				dockRoot.followSelectedDrone = false;
				dockRoot.autoFollowSuppressed = true;
			}
		}

		MapModeToolbar {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.margins: Style.overlayMargin
			mapMode: dockRoot.mapMode
			activePlanningTool: dockRoot.activePlanningTool
			activeTrackingTool: dockRoot.activeTrackingTool
			returnHomeAfterMission: dockRoot.returnHomeAfterMission
			landAfterMission: dockRoot.landAfterMission
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
				} else if (tool === "endaction") {
					// Cycle: Normal → Return home → Land → Normal
					if (dockRoot.returnHomeAfterMission) {
						dockRoot.missionPlan.landAfterMission = true;
					} else if (dockRoot.landAfterMission) {
						dockRoot.missionPlan.landAfterMission = false;
					} else {
						dockRoot.missionPlan.returnHomeAfterMission = true;
						dockRoot.ensureVisibleHomePoint();
					}
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
				if (tool === "focus-go")
					dockRoot.focusFlyTarget("go");
				else if (tool === "focus-look")
					dockRoot.focusFlyTarget("look");
				else if (tool === "focus-home")
					dockRoot.focusFlyTarget("home");
			}
		}

		ButtonGroup {
			id: missionOverlay
			z: 5
			anchors.left: parent.left
			anchors.bottom: parent.bottom
			anchors.margins: Style.overlayMargin
			title: "MISSION  " + dockRoot.missionStatusText() + "  " + dockRoot.missionItems.length + " WP  " + dockRoot.missionDistanceText() + (dockRoot.returnHomeAfterMission ? "  RTH" : dockRoot.landAfterMission ? "  LAND" : "")
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
			id: missionConfirmPanel
			z: 7
			anchors.left: missionOverlay.left
			anchors.bottom: missionOverlay.top
			anchors.bottomMargin: Style.sectionSpacing
			title: dockRoot.missionConfirmText()
			horizontal: true
			visible: missionOverlay.visible && dockRoot.missionConfirmOpen

			IconButton {
				iconName: "dialog-ok"
				label: "Confirm"
				labelColor: dockRoot.missionConfirmAction === "clear" ? "#ff6b6b" : "#6bffb8"
				enabled: dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.selectedDrone.droneUid === dockRoot.missionConfirmDroneUid
				onClicked: dockRoot.confirmMissionCommand()
			}
			IconButton {
				iconName: "dialog-cancel"
				label: "Cancel"
				labelColor: "#ffd06b"
				onClicked: dockRoot.cancelMissionConfirmation()
			}
		}

		ButtonGroup {
			id: missionLibraryPanel
			z: 6
			anchors.left: missionOverlay.left
			anchors.bottom: dockRoot.missionConfirmOpen ? missionConfirmPanel.top : missionOverlay.top
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

				Row {
					spacing: Style.sectionSpacing

					IconButton {
						iconName: "document-save"
						label: "Export"
						enabled: dockRoot.missionItems.length > 0
						onClicked: missionExportDialog.open()
					}
					IconButton {
						iconName: "document-open"
						label: "Import"
						onClicked: missionImportDialog.open()
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
			title: dockRoot.selectedMissionItemData ? "WAYPOINT " + (dockRoot.selectedMissionItemIndex + 1) : "WAYPOINT"
			horizontal: true
			visible: dockRoot.mapMode === 1 && dockRoot.selectedMissionItemData !== null

			IconButton {
				iconName: "configure"
				label: "Config"
				checkable: true
				checked: dockRoot.waypointConfigOpen
				onClicked: dockRoot.waypointConfigOpen = checked
			}
			IconButton {
				iconName: dockRoot.selectedMissionItemData && dockRoot.selectedMissionItemData.flyThrough ? "media-seek-forward" : "media-playback-pause"
				label: dockRoot.selectedMissionItemData && dockRoot.selectedMissionItemData.flyThrough ? "Fly through" : "Stop at WP"
				checkable: true
				checked: dockRoot.selectedMissionItemData ? dockRoot.selectedMissionItemData.flyThrough : false
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
					value: dockRoot.selectedMissionItemData ? dockRoot.selectedMissionItemData.speed : 0
					optionEnabled: dockRoot.selectedMissionItemData ? dockRoot.selectedMissionItemData.speedEnabled : false
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
					value: dockRoot.selectedMissionItemData ? dockRoot.selectedMissionItemData.acceptanceRadius : 0
					optionEnabled: dockRoot.selectedMissionItemData ? dockRoot.selectedMissionItemData.acceptanceRadiusEnabled : false
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
					value: dockRoot.selectedMissionItemData ? dockRoot.selectedMissionItemData.loiter : 0
					optionEnabled: dockRoot.selectedMissionItemData ? dockRoot.selectedMissionItemData.loiterEnabled : false
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
				MissionOptionEditor {
					title: "Heading"
					suffix: "°"
					value: dockRoot.selectedMissionItemData && dockRoot.selectedMissionItemData.heading !== undefined ? dockRoot.selectedMissionItemData.heading : 0
					optionEnabled: dockRoot.selectedMissionItemData ? dockRoot.selectedMissionItemData.headingEnabled === true : false
					minimumValue: 0
					maximumValue: 359
					decimals: 0
					onOptionEnabledEdited: function (enabled) {
						dockRoot.setSelectedMissionOptionEnabled("headingEnabled", enabled);
					}
					onValueEdited: function (value) {
						dockRoot.setSelectedMissionHeading(value);
					}
				}
			}
		}

		ButtonGroup {
			id: mapContextMenu
			z: 20
			x: Math.max(Style.overlayMargin, Math.min(parent.width - width - Style.overlayMargin, dockRoot.mapContextX))
			y: Math.max(Style.overlayMargin, Math.min(parent.height - height - Style.overlayMargin, dockRoot.mapContextY))
			title: "MAP ACTIONS"
			visible: dockRoot.mapMode === 2 && dockRoot.mapContextOpen

			Column {
				spacing: Style.sectionSpacing

				Button {
					id: goContextAction
					width: 132
					height: 30
					enabled: dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.hasPosition(dockRoot.selectedDrone)
					onClicked: dockRoot.requestFlyAction("go", dockRoot.mapContextCoordinate)
					background: Rectangle {
						radius: 3
						color: goContextAction.pressed ? Style.iconBtnPressedBg : goContextAction.hovered ? Style.iconBtnHoverBg : "transparent"
					}
					contentItem: Row {
						spacing: 9
						anchors.verticalCenter: parent.verticalCenter
						Image {
							width: 20
							height: 20
							source: "image://icon/mark-location"
						}
						Text {
							text: "Go Here"
							color: Style.iconBtnLabelColor
							font.pixelSize: 11
							anchors.verticalCenter: parent.verticalCenter
						}
					}
				}
				Button {
					id: lookContextAction
					width: 132
					height: 30
					enabled: dockRoot.selectedDrone && dockRoot.selectedDrone.connected && dockRoot.hasPosition(dockRoot.selectedDrone)
					onClicked: dockRoot.requestFlyAction("look", dockRoot.mapContextCoordinate)
					background: Rectangle {
						radius: 3
						color: lookContextAction.pressed ? Style.iconBtnPressedBg : lookContextAction.hovered ? Style.iconBtnHoverBg : "transparent"
					}
					contentItem: Row {
						spacing: 9
						anchors.verticalCenter: parent.verticalCenter
						Image {
							width: 20
							height: 20
							source: "image://icon/transform-rotate"
						}
						Text {
							text: "Look Here"
							color: Style.iconBtnLabelColor
							font.pixelSize: 11
							anchors.verticalCenter: parent.verticalCenter
						}
					}
				}
				Button {
					id: homeContextAction
					width: 132
					height: 30
					enabled: dockRoot.selectedDrone && dockRoot.selectedDrone.connected
					onClicked: {
						dockRoot.setHomePoint(dockRoot.mapContextCoordinate, true);
						dockRoot.guided.closeMapContext();
					}
					background: Rectangle {
						radius: 3
						color: homeContextAction.pressed ? Style.iconBtnPressedBg : homeContextAction.hovered ? Style.iconBtnHoverBg : "transparent"
					}
					contentItem: Row {
						spacing: 9
						anchors.verticalCenter: parent.verticalCenter
						Image {
							width: 20
							height: 20
							source: "image://icon/go-home-large"
						}
						Text {
							text: "Set Home"
							color: Style.iconBtnLabelColor
							font.pixelSize: 11
							anchors.verticalCenter: parent.verticalCenter
						}
					}
				}
			}
		}

		ButtonGroup {
			id: flyTargetOverlay
			z: 5
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.bottom: parent.bottom
			anchors.margins: Style.overlayMargin
			title: dockRoot.flyPromptKind === "go" ? "GO HERE  " + Math.round(dockRoot.goTargetAltitude) + "m  " + Math.round(dockRoot.goTargetHeading) + "°" : "LOOK HERE  " + Math.round(dockRoot.lookTargetHeading) + "°"
			horizontal: true
			visible: dockRoot.mapMode === 2 && dockRoot.flyPromptOpen

			IconButton {
				iconName: "dialog-ok"
				label: "Confirm"
				labelColor: "#6bffb8"
				enabled: dockRoot.selectedDrone && dockRoot.selectedDrone.connected
				onClicked: dockRoot.confirmFlyPrompt()
			}
			IconButton {
				iconName: "edit-delete"
				label: "Delete"
				labelColor: "#ff6b6b"
				visible: dockRoot.guided.snapshotValid
				onClicked: dockRoot.deleteFlyPromptTarget()
			}
			IconButton {
				iconName: "dialog-cancel"
				label: "Cancel"
				labelColor: "#ffd06b"
				onClicked: dockRoot.closeFlyPrompt()
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
			enabled: dockRoot.selectedDroneIndex >= 0 || (dockRoot.mapMode === 1 && dockRoot.selectedMissionItemData !== null) || (dockRoot.mapMode === 2 && dockRoot.flyPromptOpen && dockRoot.flyPromptKind === "go" && dockRoot.goTargetValid)
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			altitude: dockRoot.mapMode === 1 && dockRoot.selectedMissionItemData ? dockRoot.selectedMissionItemData.altitude : (dockRoot.mapMode === 2 && dockRoot.flyPromptOpen && dockRoot.flyPromptKind === "go" ? dockRoot.goTargetAltitude : (dockRoot.selectedDrone ? dockRoot.selectedDrone.altitude : 0))
			darkMode: mapSettings.isDark
			liveEdit: dockRoot.mapMode === 1 && dockRoot.selectedMissionItemData !== null
			immediateTargetEdit: dockRoot.mapMode === 2 && dockRoot.flyPromptOpen && dockRoot.flyPromptKind === "go"
			minimumAltitude: liveEdit ? 5 : 0
			z: 1
			onTargetEdited: function (target) {
				if (dockRoot.mapMode === 2 && dockRoot.flyPromptOpen && dockRoot.flyPromptKind === "go")
					dockRoot.guided.goTargetAltitude = target;
				else
					dockRoot.setSelectedMissionAltitude(target);
			}
			onTargetConfirmed: function (target) {
				if (!altTape.liveEdit && dockRoot.mapMode === 2 && dockRoot.flyPromptOpen && dockRoot.flyPromptKind === "go") {
					dockRoot.guided.goTargetAltitude = target;
				} else if (!altTape.liveEdit && dockRoot.selectedDrone) {
					dockRoot._targetStore[String(dockRoot.selectedDrone.droneUid)] = {
						"alt": target,
						"locked": true
					};
					dockRoot.selectedDrone.setAltitude(target);
				}
			}
			onTargetReset: {
				if (!altTape.liveEdit && dockRoot.mapMode === 2 && dockRoot.flyPromptOpen && dockRoot.flyPromptKind === "go") {
					dockRoot.guided.goTargetAltitude = dockRoot.selectedDrone ? dockRoot.selectedDrone.altitude : 0;
				} else if (!altTape.liveEdit && dockRoot.selectedDrone) {
					dockRoot._targetStore[String(dockRoot.selectedDrone.droneUid)] = {
						"alt": 0,
						"locked": false
					};
				}
			}
		}
	}
}
