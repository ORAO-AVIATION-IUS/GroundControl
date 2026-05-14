import Agc.Camera
import Agc.Components
import QtQuick
import QtQuick.Controls
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: dockRoot

	required property int cameraId
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
			streamId: dockRoot.cameraId
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
