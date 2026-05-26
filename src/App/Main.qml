pragma ComponentBehavior: Bound

import Agc.Camera
import Agc.Log
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

	function rowForId(id) {
		for (let i = 0; i < cameraModel.count; ++i) {
			if (cameraModel.get(i).cameraId === id)
				return i;
		}
		return -1;
	}

	function openAddDialog() {
		cameraDialog.editingId = -1;
		cameraDialog.open();
	}

	function openEditDialog(id) {
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
			const url = connectionUrl.trim();
			if (url !== "")
				console.log("Drone connect requested:", url);
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
		uniqueName: "MainLayout-7"
		Component.onCompleted: {
			addDockWidget(swarmPanel, KDDW.KDDockWidgets.Location_OnTop);
			addDockWidget(mapPanel, KDDW.KDDockWidgets.Location_OnBottom);
			addDockWidget(logPanel, KDDW.KDDockWidgets.Location_OnBottom);
			logPanel.close();
			mapPanel.raise();
		}

		MapPanel {
			id: mapPanel
		}
		SwarmPanel {
			id: swarmPanel

			onDetachLogRequested: function (source) {
				swarmPanel.logDetached = true;
			}
			onLogDetachedChanged: {
				if (logDetached) {
					logPanel.show();
					try { logPanel.setFloating(true); } catch (e) { /* fallback */ }
					logPanel.raise();
				} else if (logPanel.isOpen) {
					logPanel.close();
				}
			}
		}
		LogPanel {
			id: logPanel
			onIsOpenChanged: {
				if (!isOpen && swarmPanel.logDetached)
					swarmPanel.logDetached = false;
			}
		}

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
				onEditRequested: window.openEditDialog(model.cameraId)
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
				"label": qsTr("Drone Control"),
				"dock": swarmPanel
			}
		]
		cameraModel: cameraModel
		cameraDocks: cameraDocks
		onAddCameraRequested: window.openAddDialog()
		onAddDroneRequested: droneDialog.open()
	}
}
