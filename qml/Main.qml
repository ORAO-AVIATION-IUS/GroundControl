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
		uniqueName: "MainLayout-1"
		Component.onCompleted: {
			addDockWidget(leftPanel, KDDW.KDDockWidgets.Location_OnLeft);
			addDockWidget(rightPanel, KDDW.KDDockWidgets.Location_OnRight);
			addDockWidget(bottomPanel, KDDW.KDDockWidgets.Location_OnBottom);
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
