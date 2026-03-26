import QtQuick 2.6
import QtQuick.Controls 2.12
import "qrc:/resources/components"

Rectangle {
	id: rootPanel
	color: '#ffffff'

	property bool menuOpen: false

	Row {
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.margins: 15
		spacing: 15

		SettingsButton {
			onClicked: menuOpen = !menuOpen
		}

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

	Popup {
		id: menuPopup
		y: 50
		x: 15
		modal: false
		focus: false
		closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
		visible: menuOpen

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

			NormalButton {
				text: "Test4"
				onClicked: console.log("Test4")
			}

			NormalButton {
				text: "Test5"
				onClicked: console.log("Test5")
			}
		}
	}

	BatteryIndicator {
		anchors.top: parent.top
		anchors.right: parent.right
		anchors.margins: 15
	}
}
