import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
	id: dialog

	property alias cameraName: nameField.text
	property alias connectionString: connectionField.text

	title: qsTr("Add Camera Connection")
	modal: true
	standardButtons: Dialog.Ok | Dialog.Cancel
	anchors.centerIn: Overlay.overlay
	width: 420
	padding: 16

	onAboutToShow: {
		nameField.clear();
		connectionField.clear();
		nameField.forceActiveFocus();
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
