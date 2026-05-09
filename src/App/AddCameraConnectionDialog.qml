import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
	id: dialog

	property alias cameraName: nameField.text
	property alias connectionString: connectionField.text
	// -1 = add mode; otherwise the id of the camera being edited.
	property int editingId: -1

	title: editingId === -1 ? qsTr("Add Camera Connection") : qsTr("Edit Camera Connection")
	modal: true
	standardButtons: Dialog.Ok | Dialog.Cancel
	anchors.centerIn: Overlay.overlay
	width: 420
	padding: 16

	onAboutToShow: {
		if (editingId === -1) {
			nameField.clear();
			connectionField.clear();
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
			text: qsTr("Connection string")
		}
		TextField {
			id: connectionField
			Layout.fillWidth: true
			placeholderText: qsTr("e.g. rtsp://192.168.1.10:554/stream")
		}
	}
}
