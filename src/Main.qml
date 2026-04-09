import QtQuick 2.6
import QtQuick.Controls 2.12
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
			addDockWidget(leftPanel, KDDW.KDDockWidgets.Location_OnLeft);
			addDockWidget(rightPanel, KDDW.KDDockWidgets.Location_OnRight);
			addDockWidget(bottomPanel, KDDW.KDDockWidgets.Location_OnBottom);
			addDockWidget(testPanel, KDDW.KDDockWidgets.Location_OnTop);
			addDockWidget(compassPanel, KDDW.KDDockWidgets.Location_OnLeft);
			addDockWidget(videoPanel, KDDW.KDDockWidgets.Location_OnRight);
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
			id: bottomPanel
			uniqueName: "bottomPanel"
			title: qsTr("Bottom Panel")
			source: "qrc:/src/BottomPanel.qml"
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

		KDDW.DockWidget {
			id: videoPanel
			uniqueName: "videoPanel"
			title: qsTr("Video Stream")
			source: "qrc:/src/VideoStreamPanel.qml"
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
