import QtQuick
import QtQuick.Controls
import com.kdab.dockwidgets 2.0 as KDDW

ApplicationWindow {
	visible: true
	width: 1200
	height: 800
	title: qsTr("Ground Control")
	color: "#1e2126"

	KDDW.DockingArea {
		id: root

		anchors.fill: parent
		uniqueName: "MainLayout-3"
		Component.onCompleted: {
			addDockWidget(mapPanel, KDDW.KDDockWidgets.Location_OnBottom);
			addDockWidget(compassPanel, KDDW.KDDockWidgets.Location_OnLeft);
			addDockWidget(videoPanel, KDDW.KDDockWidgets.Location_OnRight);

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
			id: videoPanel
			uniqueName: "videoPanel"
			title: qsTr("Video Stream")
			source: "qrc:/src/VideoStreamPanel.qml"
		}
	}

	menuBar: MenuBar {
		palette.windowText: "#cdd6e0"
		palette.text: "#cdd6e0"
		palette.buttonText: "#cdd6e0"
		palette.highlightedText: "#ffffff"
		palette.highlight: "#0e76ff"
		palette.window: "#1e2126"
		palette.base: "#25282d"
		palette.button: "#303338"

		background: Rectangle {
			color: "#1e2126"
		}

		Menu {
			title: qsTr("&File")

			Action {
				text: qsTr("&Quit")
				onTriggered: Qt.quit()
			}
		}
	}
}
