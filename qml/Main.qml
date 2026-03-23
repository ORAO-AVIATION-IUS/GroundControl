import QtQuick 2.6
import QtQuick.Controls 2.12
import com.kdab.dockwidgets 2.0 as KDDW

ApplicationWindow {
	visible: true
	width: 1200
	height: 800
	title: qsTr("Ground Control")

	//topnavbar bar
	header:TopNavBar{
		id: mainNavBar

	}

	KDDW.DockingArea {
		id: root

		anchors.fill: parent
		uniqueName: "MainLayout-3"
		Component.onCompleted: {
			addDockWidget(leftPanel, KDDW.KDDockWidgets.Location_OnLeft);
			addDockWidget(rightPanel, KDDW.KDDockWidgets.Location_OnRight);
			addDockWidget(bottomPanel, KDDW.KDDockWidgets.Location_OnBottom);
			addDockWidget(compassPanel, KDDW.KDDockWidgets.Location_OnLeft);
			addDockWidget(testPanel, KDDW.KDDockWidgets.Location_OnTop);
		}

		KDDW.DockWidget {
			id: leftPanel
			uniqueName: "leftPanel"
			title: qsTr("Left Panel")
			source: "qrc:/qml/LeftPanel.qml"
		}

		KDDW.DockWidget {
			id: rightPanel
			uniqueName: "rightPanel"
			title: qsTr("Right Panel")
			source: "qrc:/qml/RightPanel.qml"
		}

		KDDW.DockWidget {
			id: bottomPanel
			uniqueName: "bottomPanel"
			title: qsTr("Bottom Panel")
			source: "qrc:/qml/BottomPanel.qml"
		}

		KDDW.DockWidget {
			id: compassPanel
			uniqueName: "compassPanel"
			title: qsTr("compass Panel")
			source: "qrc:/qml/CompassPanel.qml"
		}

		KDDW.DockWidget {
			id: testPanel
			uniqueName: "testPanel"
			title: qsTr("Test Panel")
			source: "qrc:/qml/ButtonTestPanel.qml"
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
		Menu{
					title: qsTr("&Widgets")

			Action {
				text: qsTr("Show Left Panel")
				onTriggered: leftPanel.open()
			}
			Action {
				text: qsTr("Show Right Panel")
				onTriggered: rightPanel.open()
			}
			Action {
				text: qsTr("Show Bottom Panel")
				onTriggered: bottomPanel.open()
			}
			Action {
				text: qsTr("Show Compass Panel")
				onTriggered: compassPanel.open()
			}

			MenuSeparator { }

			Action {
				text: qsTr("Show All")
				onTriggered: {
					leftPanel.open(); rightPanel.open();
					bottomPanel.open(); compassPanel.open();
				}
			}
			Action {
				text: qsTr("Hide All")
				onTriggered: {
					leftPanel.close(); rightPanel.close();
					bottomPanel.close(); compassPanel.close();
				}
			}
		}
	}
	
}
