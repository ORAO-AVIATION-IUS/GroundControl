import QtQuick 2.6
import QtQuick.Controls 2.6
import QtQuick.Layouts 1.3

Rectangle {
	color: "#e0e0e0"
	ColumnLayout {
		Button {
			text: "Take off"
			onClicked: console.log("Take off button clicked")
		}
		Button {
			text: "Land"
			onClicked: console.log("Land button clicked")
		}
	}
}
