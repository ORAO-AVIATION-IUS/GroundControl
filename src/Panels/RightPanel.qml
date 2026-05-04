import QtQuick
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: root
	uniqueName: "rightPanel"
	title: qsTr("Right Panel")

	Rectangle {
		anchors.fill: parent
		color: "#d0e0e0"
	}
}
