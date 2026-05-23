import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
	id: root

	property var targetDrone: null

	function openFor(drone) {
		targetDrone = drone;
		nameField.text = drone.droneName;
		open();
	}

	parent: Overlay.overlay
	anchors.centerIn: parent
	title: qsTr("Rename Drone")
	modal: true
	standardButtons: Dialog.Ok | Dialog.Cancel
	onAccepted: {
		if (targetDrone && nameField.text.trim() !== "")
			targetDrone.droneName = nameField.text.trim();
	}

	TextField {
		id: nameField
		placeholderText: qsTr("Drone name")
		Layout.fillWidth: true
	}
}
