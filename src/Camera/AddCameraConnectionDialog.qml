import Agc.Mavlink
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
	id: dialog

	property alias cameraName: nameField.text
	property alias connectionString: connectionField.text
	property alias pipelineString: pipelineField.text
	property alias useCustomPipeline: customToggle.checked
	// -1 = add mode; otherwise the id of the camera being edited.
	property int editingId: -1
	// UID of the drone this camera is assigned to; -1 = Global (no drone).
	property int selectedDroneUid: droneCombo.currentValue !== undefined ? droneCombo.currentValue : -1

	// Drone choices: a "Global" entry followed by the connected drones.
	readonly property var droneOptions: {
		const arr = [{
			"label": qsTr("Global (no drone)"),
			"uid": -1
		}];
		const drones = SwarmManager.droneList;
		for (let i = 0; i < drones.length; ++i)
			arr.push({
				"label": drones[i].droneName,
				"uid": drones[i].droneUid
			});
		return arr;
	}

	function setDroneUid(uid) {
		for (let i = 0; i < droneOptions.length; ++i) {
			if (droneOptions[i].uid === uid) {
				droneCombo.currentIndex = i;
				return;
			}
		}
		droneCombo.currentIndex = 0;
	}

	title: editingId === -1 ? qsTr("Add Camera Connection") : qsTr("Edit Camera Connection")
	modal: true
	standardButtons: Dialog.Ok | Dialog.Cancel
	anchors.centerIn: Overlay.overlay
	width: 480
	padding: 16

	onAboutToShow: {
		if (editingId === -1) {
			nameField.clear();
			connectionField.clear();
			pipelineField.clear();
			customToggle.checked = false;
			droneCombo.currentIndex = 0;
		}
		nameField.forceActiveFocus();
	}

	Component.onCompleted: {
		standardButton(Dialog.Ok).enabled = Qt.binding(() => nameField.text.trim() !== "");
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: 10

		Label {
			text: qsTr("Name")
		}
		TextField {
			id: nameField
			Layout.fillWidth: true
			placeholderText: qsTr("e.g. Front Camera")
		}

		Label {
			text: qsTr("Assign to")
		}
		ComboBox {
			id: droneCombo
			Layout.fillWidth: true
			model: dialog.droneOptions
			textRole: "label"
			valueRole: "uid"
		}

		CheckBox {
			id: customToggle
			text: qsTr("Custom GStreamer Pipeline")
		}

		Label {
			text: qsTr("Connection string")
			visible: !customToggle.checked
		}
		TextField {
			id: connectionField
			Layout.fillWidth: true
			visible: !customToggle.checked
			placeholderText: qsTr("e.g. rtsp://192.168.1.10:554/stream")
		}

		Label {
			text: qsTr("Pipeline")
			visible: customToggle.checked
		}
		TextArea {
			id: pipelineField
			Layout.fillWidth: true
			Layout.preferredHeight: 120
			visible: customToggle.checked
			placeholderText: qsTr("e.g. udpsrc port=5600 ! application/x-rtp ! rtph264depay ! decodebin")
			wrapMode: TextArea.Wrap
		}
	}
}
