import Agc.Components
import QtQuick
import QtQuick.Controls
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: dockRoot

	property string cameraName: ""
	property string connectionString: ""

	signal editRequested
	signal removeRequested

	title: cameraName !== "" ? qsTr("Camera - %1").arg(cameraName) : qsTr("Camera")

	Rectangle {
		anchors.fill: parent
		implicitWidth: 400
		implicitHeight: 300
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

		HamburgerMenu {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.margins: 4

			MenuItem {
				text: qsTr("Edit…")
				onTriggered: dockRoot.editRequested()
			}
			MenuItem {
				text: qsTr("Remove")
				onTriggered: dockRoot.removeRequested()
			}
		}
	}
}
