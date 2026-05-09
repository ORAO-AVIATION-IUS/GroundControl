import QtQuick
import QtQuick.Controls

MenuBar {
	id: bar

	// Array of { label: string, dock: KDDW.DockWidget } for the View menu.
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
		title: qsTr("&View")

		Repeater {
			model: bar.viewPanels
			delegate: MenuItem {
				required property var modelData
				text: modelData.label
				checkable: true
				checked: modelData.dock.isOpen
				onTriggered: bar.toggleDock(modelData.dock)
			}
		}
	}

	Menu {
		title: qsTr("&Camera")

		Action {
			text: qsTr("Add Connection")
			onTriggered: bar.addCameraRequested()
		}

		MenuSeparator {}

		Repeater {
			model: bar.cameraModel
			delegate: MenuItem {
				text: model.name
				checkable: true
				checked: bar.cameraDocks.itemAt(index) ? bar.cameraDocks.itemAt(index).isOpen : false
				onTriggered: bar.toggleDock(bar.cameraDocks.itemAt(index))
			}
		}
	}
}
