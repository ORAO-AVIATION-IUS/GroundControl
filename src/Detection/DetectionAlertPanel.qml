pragma ComponentBehavior: Bound

import Agc.Style as S
import QtQuick
import QtQuick.Layouts

Rectangle {
	id: root

	property string currentAlert: ""
	property var alertHistory: []
	property bool expanded: false

	function addAlert(alert) {
		if (alert === "")
			return;

		root.currentAlert = alert;

		const now = new Date();
		const time = now.getHours().toString().padStart(2, "0") + ":" + now.getMinutes().toString().padStart(2, "0") + ":" + now.getSeconds().toString().padStart(2, "0");

		let history = root.alertHistory.slice();
		history.unshift({
			time: time,
			text: alert
		});
		if (history.length > 50)
			history = history.slice(0, 50);
		root.alertHistory = history;
	}

	height: root.expanded ? 180 : 36
	color: "#CC0d0d14"
	border.color: "#2a2a3a"
	border.width: 1
	clip: true

	Column {
		anchors.fill: parent
		anchors.margins: 8
		spacing: 6

		RowLayout {
			width: parent.width
			height: 20
			spacing: 6

			Rectangle {
				Layout.alignment: Qt.AlignVCenter
				width: 8
				height: 8
				radius: 4
				color: root.currentAlert !== "" ? "#ff4444" : "#00FF41"

				SequentialAnimation on opacity {
					running: root.currentAlert !== ""
					loops: Animation.Infinite

					NumberAnimation {
						to: 0.2
						duration: 600
					}

					NumberAnimation {
						to: 1.0
						duration: 600
					}
				}
			}

			Text {
				Layout.alignment: Qt.AlignVCenter
				text: qsTr("AI ANALYSIS")
				color: "#aaaacc"
				font.pixelSize: 11
				font.letterSpacing: 2
				font.family: S.Style.fontFamily
			}

			Text {
				Layout.alignment: Qt.AlignVCenter
				Layout.fillWidth: true
				visible: !root.expanded
				text: root.currentAlert !== "" ? root.currentAlert : qsTr("No anomalies detected")
				color: root.currentAlert !== "" ? "#ff8888" : "#555566"
				font.pixelSize: 11
				font.family: S.Style.fontFamily
				elide: Text.ElideRight
			}

			Item {
				Layout.fillWidth: true
				visible: root.expanded
			}

			Text {
				Layout.alignment: Qt.AlignVCenter
				text: root.expanded ? qsTr("▼ collapse") : qsTr("▲ history")
				color: "#555577"
				font.pixelSize: 10
				font.family: S.Style.fontFamily

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: root.expanded = !root.expanded
				}
			}
		}

		Rectangle {
			visible: root.expanded
			width: parent.width
			height: 1
			color: "#2a2a3a"
		}

		Rectangle {
			visible: root.expanded
			width: parent.width
			height: currentAlertText.implicitHeight + 12
			radius: 4
			color: root.currentAlert !== "" ? "#33ff4444" : "#1a1a2a"
			border.color: root.currentAlert !== "" ? "#ff4444" : "#2a2a3a"
			border.width: 1

			Text {
				id: currentAlertText
				anchors.fill: parent
				anchors.margins: 6
				text: root.currentAlert !== "" ? root.currentAlert : qsTr("No anomalies detected")
				color: root.currentAlert !== "" ? "#ff8888" : "#555566"
				font.pixelSize: 12
				font.family: S.Style.fontFamily
				wrapMode: Text.WordWrap
			}
		}

		ListView {
			id: historyList
			visible: root.expanded
			width: parent.width
			height: root.height - 36 - currentAlertText.implicitHeight - 38
			clip: true
			model: root.alertHistory
			spacing: 4
			orientation: ListView.Vertical

			delegate: Rectangle {
				id: historyDelegate

				required property var modelData

				width: historyList.width
				height: entryText.implicitHeight + timeText.implicitHeight + 12
				color: "#1a1a2a"
				radius: 3

				Text {
					id: timeText
					anchors.top: parent.top
					anchors.left: parent.left
					anchors.margins: 6
					text: historyDelegate.modelData.time
					color: "#444455"
					font.pixelSize: 9
					font.family: S.Style.fontFamily
				}

				Text {
					id: entryText
					anchors.top: timeText.bottom
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.margins: 6
					text: historyDelegate.modelData.text
					color: "#aaaacc"
					font.pixelSize: 11
					font.family: S.Style.fontFamily
					wrapMode: Text.WordWrap
				}
			}

			onCountChanged: positionViewAtEnd()
		}
	}
}
