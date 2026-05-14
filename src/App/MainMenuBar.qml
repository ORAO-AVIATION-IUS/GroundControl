pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

MenuBar {
	id: bar

	property var viewPanels: []
	property ListModel cameraModel
	property var cameraDocks

	signal addCameraRequested

	function toggleDock(dw) {
		if (!dw)
			return;
		if (dw.isOpen)
			dw.close();
		else
			dw.show();
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
				required property int id
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
