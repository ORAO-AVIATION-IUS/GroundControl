pragma ComponentBehavior: Bound

import Agc.Camera
import Agc.Components
import Agc.Detection
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

		// Only instantiate the stream (which claims the single video sink) while
		// the dock is actually open, so a closed dock releases the sink for an
		// inline drone-panel tab to use.
		Loader {
			anchors.fill: parent
			active: dockRoot.isOpen
			sourceComponent: CameraStream {
				streamId: dockRoot.cameraId
			}
		}

		DetectionSettingsPopup {
			id: detectionSettings
			x: Math.max(8, parent.width - width - 8)
			y: 42
			streamId: dockRoot.cameraId
		}

		HamburgerMenu {
			MenuItem {
				checkable: true
				checked: CameraManager.detectionEnabled(dockRoot.cameraId)
				text: qsTr("Human detection")
				onTriggered: CameraManager.setDetectionEnabled(dockRoot.cameraId, checked)
			}
			MenuItem {
				text: qsTr("Detection adjustments…")
				onTriggered: detectionSettings.open()
			}
			MenuSeparator {}
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
