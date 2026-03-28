import QtQuick 2.6
import QtQuick.Controls 2.12
import "qrc:/src/components"

Rectangle {
	id: rootPanel
	color: '#ffffff'

	Row {
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.margins: 15
		spacing: 15

		SlidersButton {
			onClicked: console.log("Sliders.")
		}

		EditButton {
			onClicked: console.log("Edit.")
		}

		CameraButton {
			onClicked: console.log("Camera.")
		}

		ArmedButton {
			onClicked: console.log("Armed.")
		}

		CancelButton {
			onClicked: console.log("Cancel.")
		}
	}

	Column {
		anchors.top: parent.top
		anchors.right: parent.right
		anchors.margins: 15
		spacing: 15

		Row {
			spacing: 10

			SettingsButton {
				onClicked: console.log("Settings.")
			}

			BatteryIndicator {}
		}

		Column {
			spacing: 15

			NormalButton {
				text: "Test1"
				onClicked: console.log("Test1")
			}

			NormalButton {
				text: "Test2"
				onClicked: console.log("Test2")
			}

			NormalButton {
				text: "Test3"
				onClicked: console.log("Test3")
			}
		}
	}
}
