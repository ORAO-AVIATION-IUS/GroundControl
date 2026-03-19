import QtQuick 2.6
import "components"

Rectangle {
	color: "#e0e0e0"

	Text {
		anchors.centerIn: parent
		text: qsTr("Left Panel")
		font.pixelSize: 24
	}

	Column {
		x: 20
		y: 20
		spacing: 15

		Repeater {
			model: ["VTOL Take off", "Transition", "Horizontal", "Vertical", "Return To Launch", "VTOL Land"]

			NormalButton {
				text: modelData

				onClicked: {
					console.log(modelData + " activated");
				}
			}
		}
	}
}
