pragma ComponentBehavior: Bound

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

	property int nextCameraId: 0

	function rowForId(id) {
		for (let i = 0; i < cameraModel.count; ++i) {
			if (cameraModel.get(i).id === id)
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
		cameraDialog.editingId = id;
		cameraDialog.open();
	}

	function removeCamera(id) {
		const row = rowForId(id);
		if (row === -1)
			return;
		const dock = cameraDocks.itemAt(row);
		if (dock)
			dock.deleteDockWidgetLater();
		cameraModel.remove(row);
	}

	ListModel {
		id: cameraModel
	}

	AddCameraConnectionDialog {
		id: cameraDialog
		onAccepted: {
			const name = cameraName.trim();
			if (name === "")
				return;
			if (editingId === -1) {
				cameraModel.append({
					"id": window.nextCameraId++,
					"name": name,
					"connection": connectionString
				});
				cameraManager.addCamera(window.nextCameraId-1, name, connectionString);
				cameraManager.initialize()
				cameraManager.startCamera(window.nextCameraId-1);
			} else {
				const row = window.rowForId(editingId);
				if (row !== -1) {
					cameraModel.set(row, {
						"id": editingId,
						"name": name,
						"connection": connectionString
					});
					cameraManager.editCamera(editingId, name, connectionString)
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
			addDockWidget(testPanel, KDDW.KDDockWidgets.Location_OnTop);
			addDockWidget(mapPanel, KDDW.KDDockWidgets.Location_OnBottom);
			addDockWidget(compassPanel, KDDW.KDDockWidgets.Location_OnLeft);

			mapPanel.addDockWidgetAsTab(leftPanel);
			mapPanel.addDockWidgetAsTab(rightPanel);
			mapPanel.raise();
		}

		LeftPanel {
			id: leftPanel
		}
		RightPanel {
			id: rightPanel
		}
		MapPanel {
			id: mapPanel
		}
		CompassPanel {
			id: compassPanel
		}
		ButtonTestPanel {
			id: testPanel
		}

		Repeater {
			id: cameraDocks
			model: cameraModel
			delegate: CameraPanel {
				id: camDock
				required property int id
				required property string name
				required property string connection
				cameraName: name
				connectionString: connection
				uniqueName: "cameraConn_" + id
				onEditRequested: window.openEditDialog(id)
				onRemoveRequested: window.removeCamera(id)
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
				"label": qsTr("Left Panel"),
				"dock": leftPanel
			},
			{
				"label": qsTr("Right Panel"),
				"dock": rightPanel
			},
			{
				"label": qsTr("Compass"),
				"dock": compassPanel
			},
			{
				"label": qsTr("Button Test"),
				"dock": testPanel
			}
		]
		cameraModel: cameraModel
		cameraDocks: cameraDocks
		onAddCameraRequested: window.openAddDialog()
	}
}
