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
	readonly property var missionPlan: selectedDrone && selectedDrone.missionPlan ? selectedDrone.missionPlan : fallbackMissionPlan
	readonly property var missionItems: missionPlan.items
	readonly property int selectedMissionItemIndex: missionPlan.selectedIndex
	readonly property int missionRevision: missionPlan.revision
	readonly property bool returnHomeAfterMission: missionPlan.returnHomeAfterMission
	readonly property bool missionUploaded: selectedDrone ? selectedDrone.missionUploaded : false
	readonly property bool missionDirty: selectedDrone ? selectedDrone.missionDirty : false
	readonly property bool missionBusy: selectedDrone ? selectedDrone.missionBusy : false
	readonly property bool missionRunning: selectedDrone ? selectedDrone.missionRunning : false
	readonly property bool missionPaused: selectedDrone ? selectedDrone.missionPaused : false
	property bool waypointConfigOpen: false
	property bool missionLibraryOpen: false
	property string missionDraftName: "Mission"
	property int missionLibraryRevision: 0
	readonly property string missionBusyText: selectedDrone ? selectedDrone.missionBusyText : ""
	readonly property string missionErrorText: localMissionError !== "" ? localMissionError : (selectedDrone ? selectedDrone.missionErrorText : "")
	property string localMissionError: ""
	property double localHomeLatitude: 0
	property double localHomeLongitude: 0
	property double localHomeAltitude: 0
	property bool localHomeValid: false
	property bool goTargetValid: false
	property double goTargetLatitude: 0
	property double goTargetLongitude: 0
	property double goTargetAltitude: 0
	property double goTargetHeading: 0
	property bool lookTargetValid: false
	property double lookTargetLatitude: 0
	property double lookTargetLongitude: 0
	property double lookTargetHeading: 0
	property bool flyPromptOpen: false
	property string flyPromptKind: ""
	property bool mapContextOpen: false
	property var mapContextCoordinate: QtPositioning.coordinate()
	property real mapContextX: 0
	property real mapContextY: 0
	property var flyEditSnapshot: ({})

	Settings {
		id: missionSettings
		category: "MissionPlanning"
		property string savedMissionPlan: ""
		property string savedMissionPlans: "{}"
	}

	MissionPlanModel {
		id: fallbackMissionPlan
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
			flyPromptOpen = false;
			mapContextOpen = false;
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
		mapContextCoordinate = coordinate;
		mapContextX = screenPoint.x;
		mapContextY = screenPoint.y;
		mapContextOpen = true;
	}

	function targetHeading(coordinate) {
		if (!coordinate || !coordinate.isValid || !selectedDrone || !hasPosition(selectedDrone))
			return 0;
		return normalizeHeading(QtPositioning.coordinate(selectedDrone.latitude, selectedDrone.longitude).azimuthTo(coordinate));
	}

	function snapshotTarget(kind) {
		if (kind === "go" && goTargetValid) {
			flyEditSnapshot = {
				"kind": "go",
				"valid": true,
				"latitude": goTargetLatitude,
				"longitude": goTargetLongitude,
				"altitude": goTargetAltitude,
				"heading": goTargetHeading
			};
		} else if (kind === "look" && lookTargetValid) {
			flyEditSnapshot = {
				"kind": "look",
				"valid": true,
				"latitude": lookTargetLatitude,
				"longitude": lookTargetLongitude,
				"heading": lookTargetHeading
			};
		} else {
			flyEditSnapshot = {
				"kind": kind,
				"valid": false
			};
		}
	}

	function applyTarget(kind, coordinate) {
		if (!coordinate || !coordinate.isValid || !selectedDrone || !hasPosition(selectedDrone))
			return;
		if (kind === "go") {
			const altitude = goTargetValid ? goTargetAltitude : selectedDrone.altitude;
			goTargetLatitude = coordinate.latitude;
			goTargetLongitude = coordinate.longitude;
			goTargetAltitude = altitude;
			goTargetHeading = targetHeading(coordinate);
			goTargetValid = true;
		} else if (kind === "look") {
			lookTargetLatitude = coordinate.latitude;
			lookTargetLongitude = coordinate.longitude;
			lookTargetHeading = targetHeading(coordinate);
			lookTargetValid = true;
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
		flyPromptKind = kind;
		flyPromptOpen = true;
		mapContextOpen = false;
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
			flyPromptOpen = false;
			flyPromptKind = "";
			return;
		}
		cancelPendingFlyEdit(kind);
		flyPromptKind = kind;
		flyPromptOpen = true;
		mapContextOpen = false;
	}

	function restoreFlyEditSnapshot() {
		if (!flyEditSnapshot || flyEditSnapshot.kind !== flyPromptKind)
			return;
		if (flyPromptKind === "go") {
			goTargetValid = flyEditSnapshot.valid === true;
			if (goTargetValid) {
				goTargetLatitude = flyEditSnapshot.latitude;
				goTargetLongitude = flyEditSnapshot.longitude;
				goTargetAltitude = flyEditSnapshot.altitude;
				goTargetHeading = flyEditSnapshot.heading;
			}
		} else if (flyPromptKind === "look") {
			lookTargetValid = flyEditSnapshot.valid === true;
			if (lookTargetValid) {
				lookTargetLatitude = flyEditSnapshot.latitude;
				lookTargetLongitude = flyEditSnapshot.longitude;
				lookTargetHeading = flyEditSnapshot.heading;
			}
		}
	}

	function closeFlyPrompt() {
		restoreFlyEditSnapshot();
		flyPromptOpen = false;
		flyPromptKind = "";
	}

	function deleteFlyPromptTarget() {
		if (flyPromptKind === "go")
			goTargetValid = false;
		else if (flyPromptKind === "look")
			lookTargetValid = false;
		flyPromptOpen = false;
		flyPromptKind = "";
	}

	function confirmFlyPrompt() {
		if (!selectedDrone || !selectedDrone.connected)
			return;
		if (flyPromptKind === "go" && goTargetValid)
			selectedDrone.goToLocation(goTargetLatitude, goTargetLongitude, goTargetAltitude, goTargetHeading);
		else if (flyPromptKind === "look" && lookTargetValid && hasPosition(selectedDrone))
			selectedDrone.goToLocation(selectedDrone.latitude, selectedDrone.longitude, selectedDrone.altitude, lookTargetHeading);
		flyPromptOpen = false;
		flyPromptKind = "";
		flyEditSnapshot = ({});
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
		localHomeLatitude = coordinate.latitude;
		localHomeLongitude = coordinate.longitude;
		localHomeAltitude = homeAltitudeForSetHome();
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
		localMissionError = "";
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
		missionPlan.items = plan.items;
		missionPlan.selectedIndex = missionItems.length > 0 && mapMode === 1 ? 0 : -1;
		missionPlan.returnHomeAfterMission = plan.returnHomeAfterMission === true;
		missionDraftName = trimmedName;
		localMissionError = "";
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
		return missionPlan.validateForUpload();
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
		localMissionError = "";
		selectedDrone.startMission();
	}

	function requestMissionPause() {
		if (!selectedDrone || !selectedDrone.connected)
			return;
		localMissionError = "";
		selectedDrone.pauseMission();
	}

	function requestMissionClear() {
		if (selectedDrone && selectedDrone.connected) {
			localMissionError = "";
			selectedDrone.clearMission();
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
			dockRoot.mapContextOpen = false;
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
			onMapInteractionStarted: dockRoot.mapContextOpen = false
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
					dockRoot.missionPlan.returnHomeAfterMission = !dockRoot.returnHomeAfterMission;
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
				MissionOptionEditor {
					title: "Heading"
					suffix: "°"
					value: dockRoot.selectedMissionItem() && dockRoot.selectedMissionItem().heading !== undefined ? dockRoot.selectedMissionItem().heading : 0
					optionEnabled: dockRoot.selectedMissionItem() ? dockRoot.selectedMissionItem().headingEnabled === true : false
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
						dockRoot.mapContextOpen = false;
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
				visible: dockRoot.flyEditSnapshot && dockRoot.flyEditSnapshot.valid === true
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
			enabled: dockRoot.selectedDroneIndex >= 0 || (dockRoot.mapMode === 1 && dockRoot.selectedMissionItem() !== null) || (dockRoot.mapMode === 2 && dockRoot.flyPromptOpen && dockRoot.flyPromptKind === "go" && dockRoot.goTargetValid)
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			altitude: dockRoot.mapMode === 1 && dockRoot.selectedMissionItem() ? dockRoot.selectedMissionItem().altitude : (dockRoot.mapMode === 2 && dockRoot.flyPromptOpen && dockRoot.flyPromptKind === "go" ? dockRoot.goTargetAltitude : (dockRoot.selectedDrone ? dockRoot.selectedDrone.altitude : 0))
			darkMode: mapSettings.isDark
			liveEdit: dockRoot.mapMode === 1 && dockRoot.selectedMissionItem() !== null
			immediateTargetEdit: dockRoot.mapMode === 2 && dockRoot.flyPromptOpen && dockRoot.flyPromptKind === "go"
			minimumAltitude: liveEdit ? 5 : 0
			z: 1
			onTargetEdited: function (target) {
				if (dockRoot.mapMode === 2 && dockRoot.flyPromptOpen && dockRoot.flyPromptKind === "go")
					dockRoot.goTargetAltitude = target;
				else
					dockRoot.setSelectedMissionAltitude(target);
			}
			onTargetConfirmed: function (target) {
				if (!altTape.liveEdit && dockRoot.mapMode === 2 && dockRoot.flyPromptOpen && dockRoot.flyPromptKind === "go") {
					dockRoot.goTargetAltitude = target;
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
					dockRoot.goTargetAltitude = dockRoot.selectedDrone ? dockRoot.selectedDrone.altitude : 0;
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
