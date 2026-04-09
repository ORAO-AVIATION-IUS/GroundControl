import QtQuick 2.6
import QtQuick.Controls 2.12
import "qrc:/src/components"
import "qrc:/src/theme"

Rectangle {
	id: root
	color: '#ffffff'

	// Map buttons — vertical toolbar on the left
	Column {
		anchors.left: parent.left
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		anchors.margins: 6
		spacing: 6
		width: childrenRect.width

		// PATH section
		Rectangle {
			width: pathCol.implicitWidth + 20
			height: pathCol.implicitHeight + 20
			color: "#1c1f26"
			radius: 5

			Column {
				id: pathCol
				anchors.centerIn: parent
				spacing: 6

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: "PATH"
					color: "#6b7a8d"
					font.pixelSize: 7
					font.letterSpacing: 1
				}

				IconButton {
					iconName: "draw-freehand"
					label: "Draw"
					anchors.horizontalCenter: parent.horizontalCenter
					onClicked: console.log("Draw Path")
				}
				IconButton {
					iconName: "draw-eraser"
					label: "Erase"
					anchors.horizontalCenter: parent.horizontalCenter
					onClicked: console.log("Erase Path")
				}
				IconButton {
					iconName: "system-search"
					label: "Scan"
					anchors.horizontalCenter: parent.horizontalCenter
					onClicked: console.log("Scan Area")
				}
			}
		}

		// ZOOM section
		Rectangle {
			width: mapZoomCol.implicitWidth + 20
			height: mapZoomCol.implicitHeight + 20
			color: "#1c1f26"
			radius: 5

			Column {
				id: mapZoomCol
				anchors.centerIn: parent
				spacing: 6

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: "ZOOM"
					color: "#6b7a8d"
					font.pixelSize: 7
					font.letterSpacing: 1
				}

				IconButton {
					iconName: "zoom-in"
					label: "In"
					anchors.horizontalCenter: parent.horizontalCenter
					onClicked: console.log("Map Zoom In")
				}
				IconButton {
					iconName: "zoom-out"
					label: "Out"
					anchors.horizontalCenter: parent.horizontalCenter
					onClicked: console.log("Map Zoom Out")
				}
			}
		}

	}

	// Camera buttons — horizontal toolbar on the top-right
	Row {
		anchors.top: parent.top
		anchors.right: parent.right
		anchors.margins: 6
		spacing: 6

		// ZOOM section
		Rectangle {
			height: camZoomCol.implicitHeight + 20
			width: camZoomRow.implicitWidth + 20
			color: "#1c1f26"
			radius: 5

			Column {
				id: camZoomCol
				anchors.centerIn: parent
				spacing: 3

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: "ZOOM"
					color: "#6b7a8d"
					font.pixelSize: 7
					font.letterSpacing: 1
				}

				Row {
					id: camZoomRow
					spacing: 10

					IconButton {
						iconName: "zoom-in"
						label: "In"
						onClicked: console.log("Zoom In")
					}
					IconButton {
						iconName: "zoom-out"
						label: "Out"
						onClicked: console.log("Zoom Out")
					}
					IconButton {
						iconName: "zoom-fit-best"
						label: "Quick"
						onClicked: console.log("Quick Zoom")
					}
				}
			}
		}

		// MISSION section
		Rectangle {
			height: missionCol.implicitHeight + 20
			width: missionRow.implicitWidth + 20
			color: "#1c1f26"
			radius: 5

			Column {
				id: missionCol
				anchors.centerIn: parent
				spacing: 3

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: "MISSION"
					color: "#6b7a8d"
					font.pixelSize: 7
					font.letterSpacing: 1
				}

				Row {
					id: missionRow
					spacing: 10

					IconButton { iconName: "dialog-ok"; label: "Accept"; labelColor: "#6bffb8"; onClicked: console.log("Accept Path") }
					IconButton { iconName: "dialog-cancel"; label: "Cancel"; labelColor: "#ff6b6b"; onClicked: console.log("Cancel Path") }
				}
			}
		}

		// CONTROLS section
		Rectangle {
			height: camControlsCol.implicitHeight + 20
			width: camControlsRow.implicitWidth + 20
			color: "#1c1f26"
			radius: 5

			Column {
				id: camControlsCol
				anchors.centerIn: parent
				spacing: 3

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: "CONTROLS"
					color: "#6b7a8d"
					font.pixelSize: 7
					font.letterSpacing: 1
				}

				Row {
					id: camControlsRow
					spacing: 10

					IconButton {
						iconName: "view-grid"
						label: "Grid"
						onClicked: console.log("Toggle Grid")
					}
					IconButton {
						iconName: "camera-photo"
						label: "Capture"
						onClicked: console.log("Take Picture")
					}

					IconButton {
						id: camToggle
						property bool isOpen: true
						iconName: isOpen ? "camera-on" : "camera-off"
						label: isOpen ? "Close" : "Open"
						labelColor: isOpen ? "#ff6b6b" : "#6bffb8"
						onClicked: {
							isOpen = !isOpen;
							console.log(isOpen ? "Camera Opened" : "Camera Closed");
						}
					}
				}
			}
		}
	}
}
