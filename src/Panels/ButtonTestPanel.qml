import Agc.Components
import QtQuick
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: root
	uniqueName: "testPanel"
	title: qsTr("Test Panel")

	Rectangle {
		id: rootPanel
		anchors.fill: parent
		color: '#ffffff'

		Row {
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.margins: 15
			spacing: 15

			IconButton {
				iconSource: "qrc:/resources/icons/Sliders.svg"
				onClicked: console.log("Sliders.")
			}

			IconButton {
				iconSource: "qrc:/resources/icons/Edit.svg"
				onClicked: console.log("Edit.")
			}

			IconButton {
				iconSource: "qrc:/resources/icons/Camera.svg"
				onClicked: console.log("Camera.")
			}

			IconButton {
				iconSource: "qrc:/resources/icons/Armed.svg"
				onClicked: console.log("Armed.")
			}

			IconButton {
				iconSource: "qrc:/resources/icons/Cancel.svg"
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

				IconButton {
					iconSource: "qrc:/resources/icons/Settings.svg"
					onClicked: console.log("Settings.")
				}

				BatteryIndicator {}
			}

			Column {
				spacing: 8

				Btn {
					text: "Test1"
					onClicked: console.log("Test1")
				}

				Btn {
					text: "Test2"
					onClicked: console.log("Test2")
				}

				Btn {
					text: "Test3"
					onClicked: console.log("Test3")
				}
			}
		}
	}
}
