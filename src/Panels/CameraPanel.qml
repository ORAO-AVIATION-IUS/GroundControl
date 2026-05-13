import Agc.Components
import Agc.Camera
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


		CameraStream {
			playerId: dockRoot.cameraName
		}

		HamburgerMenu {
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
