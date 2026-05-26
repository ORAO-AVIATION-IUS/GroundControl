pragma ComponentBehavior: Bound

import Agc.Log
import QtQuick
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: root
	uniqueName: "logPanel"
	title: qsTr("Logs - Master")

	LogView {
		anchors.fill: parent
		boundSource: ""
		pinned: false
		showAttach: false
		showDetach: false
	}
}
