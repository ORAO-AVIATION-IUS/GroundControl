import Agc.Components
import QtQuick
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: dockRoot
	uniqueName: "mapPanel"
	title: qsTr("Map")

	MapView {
		anchors.fill: parent
	}
}
