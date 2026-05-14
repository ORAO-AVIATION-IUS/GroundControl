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
