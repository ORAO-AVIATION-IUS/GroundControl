import QtQuick 2.6
import "components"

Rectangle {
	color: "#e0d0e0"

	Text {
		anchors.centerIn: parent
		text: qsTr("Bottom Panel")
		font.pixelSize: 24
	}
	NormalButton {
		x: 50
		y: 20
		text: "Test"
		onClicked: {
			console.log("Test");
		}
	}
	NormalButton {
		x: 50
		y: 80
		text: "Test2"
		onClicked: {
			console.log("Test2");
		}
	}
}
