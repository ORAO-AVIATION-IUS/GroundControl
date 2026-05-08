import QtQuick
import QtQuick.Controls
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: dockRoot

	property string cameraName: ""
	property string connectionString: ""

	title: cameraName !== "" ? qsTr("Camera - %1").arg(cameraName) : qsTr("Camera")

	Rectangle {
		anchors.fill: parent
		color: "#222"

		Column {
			anchors.centerIn: parent
			spacing: 8

			Label {
				anchors.horizontalCenter: parent.horizontalCenter
				text: dockRoot.cameraName
				color: "white"
				font.bold: true
				font.pixelSize: 18
			}
			Label {
				anchors.horizontalCenter: parent.horizontalCenter
				text: dockRoot.connectionString
				color: "#aaa"
			}
		}
	}
}
