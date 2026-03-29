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

		SlidersToolButton {
			onClicked: console.log("Sliders.")
		}

		EditToolButton {
			onClicked: console.log("Edit.")
		}

		CameraToolButton {
			onClicked: console.log("Camera.")
		}

		ArmedToolButton {
			onClicked: console.log("Armed.")
		}

		CancelToolButton {
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

			SettingsToolButton {
				onClicked: console.log("Settings.")
			}

			BatteryIndicator {}
		}

		Column {
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
