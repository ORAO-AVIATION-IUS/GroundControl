import QtQuick
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: root
	uniqueName: "leftPanel"
	title: qsTr("Left Panel")

	Rectangle {
		anchors.fill: parent
		color: "#e0e0e0"

		Text {
			anchors.centerIn: parent
			text: qsTr("Left Panel")
			font.pixelSize: 24
		}
	}
}
