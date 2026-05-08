pragma ComponentBehavior: Bound

import Agc.Panels
import QtQuick
import QtQuick.Controls
import com.kdab.dockwidgets as KDDW

ApplicationWindow {
	id: window
	visible: true
	width: 1200
	height: 800
	title: qsTr("Ground Control")

	ListModel {
		id: cameraModel
	}

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

		LeftPanel {
			id: leftPanel
		}
		RightPanel {
			id: rightPanel
		}
		MapPanel {
			id: mapPanel
		}
		CompassPanel {
			id: compassPanel
		}
		ButtonTestPanel {
			id: testPanel
		}

		Repeater {
			id: cameraDocks
			model: cameraModel
			delegate: CameraPanel {
				id: camDock
				required property int index
				required property string name
				required property string connection
				cameraName: name
				connectionString: connection
				uniqueName: "cameraConn_" + index
				Component.onCompleted: root.addDockWidget(camDock, KDDW.KDDockWidgets.Location_OnRight)
			}
		}
	}

	menuBar: MainMenuBar {
		viewPanels: [
			{
				"label": qsTr("Map"),
				"dock": mapPanel
			},
			{
				"label": qsTr("Left Panel"),
				"dock": leftPanel
			},
			{
				"label": qsTr("Right Panel"),
				"dock": rightPanel
			},
			{
				"label": qsTr("Compass"),
				"dock": compassPanel
			},
			{
				"label": qsTr("Button Test"),
				"dock": testPanel
			}
		]
		cameraModel: cameraModel
		cameraDocks: cameraDocks
	}
}
