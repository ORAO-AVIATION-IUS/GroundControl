import QtQuick
import QtQuick.Controls
import com.kdab.dockwidgets 2.0 as KDDW

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

		KDDW.DockWidget {
			id: leftPanel
			uniqueName: "leftPanel"
			title: qsTr("Left Panel")
			source: "qrc:/src/LeftPanel.qml"
		}

		KDDW.DockWidget {
			id: rightPanel
			uniqueName: "rightPanel"
			title: qsTr("Right Panel")
			source: "qrc:/src/RightPanel.qml"
		}

		KDDW.DockWidget {
			id: mapPanel
			uniqueName: "mapPanel"
			title: qsTr("Map")
			source: "qrc:/src/MapView.qml"
		}

		KDDW.DockWidget {
			id: compassPanel
			uniqueName: "compassPanel"
			title: qsTr("compass Panel")
			source: "qrc:/src/CompassPanel.qml"
		}

		KDDW.DockWidget {
			id: testPanel
			uniqueName: "testPanel"
			title: qsTr("Test Panel")
			source: "qrc:/src/ButtonTestPanel.qml"
		}
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
