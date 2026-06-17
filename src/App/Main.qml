pragma ComponentBehavior: Bound

import Agc.Camera
import Agc.Mavlink
import Agc.Panels
import QtQuick
import QtQuick.Controls
import com.kdab.dockwidgets as KDDW

ApplicationWindow {
	id: window
	visible: true
	width: 1200
	height: 800
	title: qsTr("Ground Control")
	color: "#0d1117"

	palette.window: "#0d1117"
	palette.windowText: "#e6edf3"
	palette.base: "#161b22"
	palette.alternateBase: "#1c2128"
	palette.text: "#e6edf3"
	palette.button: "#21262d"
	palette.buttonText: "#e6edf3"
	palette.brightText: "#f85149"
	palette.highlight: "#1f6feb"
	palette.highlightedText: "#ffffff"
	palette.dark: "#30363d"
	palette.mid: "#21262d"
	palette.light: "#484f58"
	palette.midlight: "#30363d"
	palette.link: "#58a6ff"
	palette.placeholderText: "#6e7681"
	palette.toolTipBase: "#1c2128"
	palette.toolTipText: "#e6edf3"

	function rowForId(id) {
		for (let i = 0; i < cameraModel.count; ++i) {
			if (cameraModel.get(i).cameraId === id)
				return i;
		}
		return -1;
	}

	function openAddCameraDialog() {
		cameraDialog.editingId = -1;
		cameraDialog.open();
	}

	function openEditCameraDialog(id) {
		const row = rowForId(id);
		if (row === -1)
			return;
		const r = cameraModel.get(row);
		cameraDialog.cameraName = r.name;
		cameraDialog.connectionString = r.connection;
		cameraDialog.pipelineString = r.pipeline;
		cameraDialog.useCustomPipeline = r.isCustom;
		cameraDialog.editingId = id;
		cameraDialog.open();
	}

	function removeCamera(id) {
		CameraManager.removeStream(id);
		const row = rowForId(id);
		if (row === -1)
			return;
		const dock = cameraDocks.itemAt(row) as CameraPanel;
		if (dock)
			dock.deleteDockWidgetLater();
		cameraModel.remove(row);
	}

	ListModel {
		id: cameraModel
	}

	AddDroneConnectionDialog {
		id: droneDialog
		onAccepted: {
			const name = droneName.trim();
			const url = connectionUrl.trim();
			if (name !== "" && url !== "")
				SwarmManager.addDrone(name, url);
		}
	}

	AddCameraConnectionDialog {
		id: cameraDialog
		onAccepted: {
			const name = cameraName.trim();
			if (name === "")
				return;
			if (editingId === -1) {
				let streamId;
				streamId = CameraManager.addStream(name, connectionString, pipelineString, useCustomPipeline);
				cameraModel.append({
					"cameraId": streamId,
					"name": name,
					"connection": connectionString,
					"pipeline": pipelineString,
					"isCustom": useCustomPipeline
				});
			} else {
				const row = window.rowForId(editingId);
				if (row !== -1) {
					CameraManager.editStream(editingId, name, connectionString, pipelineString, useCustomPipeline);
					cameraModel.set(row, {
						"cameraId": editingId,
						"name": name,
						"connection": connectionString,
						"pipeline": pipelineString,
						"isCustom": useCustomPipeline
					});
				}
				editingId = -1;
			}
		}
		onRejected: editingId = -1
	}

	KDDW.DockingArea {
		id: root

		anchors.fill: parent
		uniqueName: "MainLayout-3"
		Component.onCompleted: {
			addDockWidget(dronePanel, KDDW.KDDockWidgets.Location_OnTop);
			addDockWidget(mapPanel, KDDW.KDDockWidgets.Location_OnBottom);
			dronePanel.show();
			mapPanel.raise();
		}

		// Selected drone panel, bound to SwarmManager.selectedDrone
		DronePanel {
			id: dronePanel
			drone: SwarmManager.selectedDrone

			title: SwarmManager.selectedDrone ? qsTr("Selected: %1").arg(SwarmManager.selectedDrone.droneName) : qsTr("Selected Drone")
		}

		MapPanel {
			id: mapPanel
		}

		// Per-drone panels (closed by default, toggled from Drone menu)

		ListModel {
			id: droneModel
		}

		Connections {
			target: SwarmManager
			function onDronesChanged() {
				let i = 0;
				while (i < droneModel.count && i < SwarmManager.droneCount) {
					let d = SwarmManager.droneAt(i);
					if (droneModel.get(i).uid !== d.droneUid) {
						let found = false;
						for (let j = i; j < droneModel.count; ++j) {
							if (droneModel.get(j).uid === d.droneUid) {
								found = true;
								break;
							}
						}
						if (!found)
							droneModel.remove(i);
						else
							++i;
					} else {
						++i;
					}
				}
				while (droneModel.count > SwarmManager.droneCount)
					droneModel.remove(droneModel.count - 1);
				for (let k = droneModel.count; k < SwarmManager.droneCount; ++k) {
					let d = SwarmManager.droneAt(k);
					droneModel.append({
						"uid": d.droneUid,
						"droneRef": d
					});
				}
			}
		}

		Repeater {
			id: dronePanelDocks
			model: droneModel
			delegate: DronePanel {
				id: perDroneDock
				required property var model

				drone: model.droneRef
				uniqueName: "dronePanel_" + model.uid

				Connections {
					target: SwarmManager
					function onDroneAboutToBeRemoved(uid) {
						if (uid !== perDroneDock.model.uid)
							return;
						perDroneDock.close();
						perDroneDock.drone = null;
					}
				}

				Component.onCompleted: {
					root.addDockWidget(perDroneDock, KDDW.KDDockWidgets.Location_OnBottom, dronePanel);
					close();
				}
			}
		}

		// Camera panels
		Repeater {
			id: cameraDocks
			model: cameraModel
			delegate: CameraPanel {
				id: camDock
				required property var model
				cameraId: model.cameraId
				cameraName: model.name
				connectionString: model.connection
				uniqueName: "cameraConn_" + model.cameraId
				onEditRequested: window.openEditCameraDialog(model.cameraId)
				onRemoveRequested: window.removeCamera(model.cameraId)
				Component.onCompleted: root.addDockWidget(camDock, KDDW.KDDockWidgets.Location_OnRight)
			}
		}
	}

	menuBar: MainMenuBar {
		viewPanels: [
			{
				"label": qsTr("Map"),
				"dock": mapPanel
			},
			{
				"label": qsTr("Selected Drone"),
				"dock": dronePanel
			}
		]
		cameraModel: cameraModel
		cameraDocks: cameraDocks
		dronePanelDocks: dronePanelDocks
		onAddCameraRequested: window.openAddCameraDialog()
		onAddDroneRequested: droneDialog.open()
	}
}
