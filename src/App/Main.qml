import QtQuick
import QtQuick.Controls
import com.kdab.dockwidgets as KDDW
import Agc.Panels

ApplicationWindow {
	visible: true
	width: 1200
	height: 800
	title: qsTr("Ground Control")

	KDDW.DockingArea {
		id: root

		anchors.fill: parent
		uniqueName: "MainLayout-3"
		Component.onCompleted: {
			addDockWidget(testPanel, KDDW.KDDockWidgets.Location_OnTop);
			addDockWidget(mapPanel, KDDW.KDDockWidgets.Location_OnBottom);
			addDockWidget(compassPanel, KDDW.KDDockWidgets.Location_OnLeft);

			mapPanel.addDockWidgetAsTab(leftPanel);
			mapPanel.addDockWidgetAsTab(rightPanel);
			mapPanel.raise();
		}

		LeftPanel       { id: leftPanel }
		RightPanel      { id: rightPanel }
		MapPanel        { id: mapPanel }
		CompassPanel    { id: compassPanel }
		ButtonTestPanel { id: testPanel }
	}

	menuBar: MenuBar {
		Menu {
			title: qsTr("&File")

			Action {
				text: qsTr("&Quit")
				onTriggered: Qt.quit()
			}
		}
	}
}
