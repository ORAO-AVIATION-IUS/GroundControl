pragma ComponentBehavior: Bound

import Agc.Mavlink
import QtQuick
import QtQuick.Controls

MenuBar {
	id: bar

	property var viewPanels: []
	property ListModel cameraModel
	property var cameraDocks
	property var dronePanelDocks

	signal addCameraRequested
	signal addDroneRequested

	function toggleDock(dw) {
		if (!dw)
			return;
		if (dw.isOpen)
			dw.close();
		else
			dw.show();
	}

	function findDroneDock(uid) {
		if (!dronePanelDocks)
			return null;
		for (let i = 0; i < dronePanelDocks.count; ++i) {
			let dock = dronePanelDocks.itemAt(i);
			if (dock && dock.drone && dock.drone.droneUid === uid)
				return dock;
		}
		return null;
	}

	function allDronePanelsOpen() {
		if (!dronePanelDocks || dronePanelDocks.count === 0)
			return false;
		for (let i = 0; i < dronePanelDocks.count; ++i) {
			let dock = dronePanelDocks.itemAt(i);
			if (!dock || !dock.isOpen)
				return false;
		}
		return true;
	}

	function toggleAllDronePanels() {
		if (!dronePanelDocks)
			return;
		let shouldClose = allDronePanelsOpen();
		for (let i = 0; i < dronePanelDocks.count; ++i) {
			let dock = dronePanelDocks.itemAt(i);
			if (!dock)
				continue;
			if (shouldClose)
				dock.close();
			else if (!dock.isOpen)
				dock.show();
		}
	}

	Menu {
		title: qsTr("&File")

		Action {
			text: qsTr("&Quit")
			onTriggered: Qt.quit()
		}
	}

	Menu {
		id: viewMenu
		title: qsTr("&View")

		Instantiator {
			model: bar.viewPanels
			delegate: MenuItem {
				required property var modelData
				text: modelData.label
				checkable: true
				checked: modelData.dock.isOpen
				onTriggered: bar.toggleDock(modelData.dock)
			}
			onObjectAdded: (index, object) => viewMenu.insertItem(index, object)
			onObjectRemoved: (index, object) => viewMenu.removeItem(object)
		}
	}

	Menu {
		id: droneMenu
		title: qsTr("&Drone")

		Action {
			text: qsTr("New Connection…")
			onTriggered: bar.addDroneRequested()
		}

		Action {
			text: bar.allDronePanelsOpen() ? qsTr("Close All Panels") : qsTr("Show All Panels")
			enabled: bar.dronePanelDocks && bar.dronePanelDocks.count > 0
			onTriggered: bar.toggleAllDronePanels()
		}

		MenuSeparator {}

		Instantiator {
			model: SwarmManager.droneList
			delegate: Menu {
				id: droneSubmenu

				required property var modelData
				required property int index

				title: modelData.droneName

				Action {
					text: qsTr("Show Panel")
					checkable: true
					checked: {
						let dock = bar.findDroneDock(droneSubmenu.modelData.droneUid);
						return dock ? dock.isOpen : false;
					}
					onTriggered: bar.toggleDock(bar.findDroneDock(droneSubmenu.modelData.droneUid))
				}

				Action {
					text: SwarmManager.selectedDroneIndex === droneSubmenu.index ? qsTr("Deselect") : qsTr("Select")
					onTriggered: {
						if (SwarmManager.selectedDroneIndex === droneSubmenu.index)
							SwarmManager.clearSelection();
						else
							SwarmManager.selectDrone(droneSubmenu.index);
					}
				}

				Action {
					text: qsTr("Rename…")
					onTriggered: renameDialog.openFor(droneSubmenu.modelData)
				}

				Action {
					text: qsTr("Disconnect")
					onTriggered: SwarmManager.removeDroneByUid(droneSubmenu.modelData.droneUid)
				}
			}
			onObjectAdded: (index, object) => droneMenu.insertMenu(index + 3, object)
			onObjectRemoved: (index, object) => droneMenu.removeMenu(object)
		}
	}

	RenameDroneDialog {
		id: renameDialog
	}

	Menu {
		id: cameraMenu
		title: qsTr("&Camera")

		Action {
			text: qsTr("Add Connection")
			onTriggered: bar.addCameraRequested()
		}

		MenuSeparator {}

		Instantiator {
			model: bar.cameraModel
			delegate: MenuItem {
				id: cameraMenuItem
				required property int index
				required property string name
				required property int cameraId
				text: name
				checkable: true
				checked: {
					let dock = bar.cameraDocks.itemAt(index);
					return dock ? dock.isOpen : false;
				}
				onTriggered: bar.toggleDock(bar.cameraDocks.itemAt(index))
			}
			onObjectAdded: (index, object) => cameraMenu.insertItem(index + 2, object)
			onObjectRemoved: (index, object) => cameraMenu.removeItem(object)
		}
	}
}
