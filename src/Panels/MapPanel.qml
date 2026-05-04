import QtQuick
import com.kdab.dockwidgets as KDDW
import Agc.Components

KDDW.DockWidget {
	id: dockRoot
	uniqueName: "mapPanel"
	title: qsTr("Map")

	MapView {
		anchors.fill: parent
	}
}
