import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
	id: dialog

	property alias droneName: nameField.text
	property alias connectionUrl: urlField.text

	title: qsTr("Connect to Drone")
	modal: true
	standardButtons: Dialog.Ok | Dialog.Cancel
	anchors.centerIn: Overlay.overlay
	width: 420
	padding: 16

	onAboutToShow: {
		if (nameField.text === "")
			nameField.text = qsTr("PX4 SITL");
		if (urlField.text === "")
			urlField.text = "udpin://0.0.0.0:14540";
		nameField.forceActiveFocus();
	}

	Component.onCompleted: {
		standardButton(Dialog.Ok).enabled = Qt.binding(() => urlField.text.trim() !== "");
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
			placeholderText: qsTr("e.g. PX4 SITL")
		}

		Label {
			text: qsTr("Connection URL")
		}
		TextField {
			id: urlField
			Layout.fillWidth: true
			placeholderText: qsTr("e.g. udp://:14540")
		}

		Label {
			Layout.topMargin: 4
			text: qsTr("Supported formats:\n• UDP: udp://:14540\n• TCP: tcp://192.168.1.10:5760\n• Serial: serial:///dev/ttyUSB0:57600")
			font.pixelSize: 11
			color: "#888"
			wrapMode: Text.Wrap
		}
	}
}
