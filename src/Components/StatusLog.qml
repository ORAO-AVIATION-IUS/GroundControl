pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
	id: root

	property alias model: logView.model
	signal clearClicked

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 12
		spacing: 0

		RowLayout {
			Layout.fillWidth: true
			Layout.bottomMargin: 6

			Text {
				text: "STATUS LOG"
				color: "#a0a8b0"
				font.pixelSize: 9
				font.bold: true
				font.letterSpacing: 1.4
				font.family: "Segoe UI"
			}

			Item {
				Layout.fillWidth: true
			}

			Text {
				text: "CLR"
				color: clrArea.containsMouse ? "#3a4a5a" : "#b0b8c0"
				font.pixelSize: 9
				font.family: "Segoe UI"

				MouseArea {
					id: clrArea
					anchors.fill: parent
					hoverEnabled: true
					onClicked: root.clearClicked()
				}
			}
		}

		Rectangle {
			Layout.fillWidth: true
			Layout.preferredHeight: 1
			color: "#e8e8ec"
		}

		ListView {
			id: logView
			Layout.fillWidth: true
			Layout.fillHeight: true
			clip: true
			spacing: 2
			Layout.topMargin: 6

			delegate: RowLayout {
				id: logDelegate

				required property string ts
				required property string src
				required property string msg
				required property string level

				width: logView.width
				spacing: 5

				Text {
					text: logDelegate.ts
					color: "#b0b8c4"
					font.pixelSize: 9
					font.family: "Segoe UI"
				}
				Text {
					text: "[" + logDelegate.src + "]"
					Layout.preferredWidth: 36
					color: logDelegate.src === "SYS" ? "#2a5080" : "#6a4010"
					font.pixelSize: 9
					font.bold: true
					font.family: "Segoe UI"
				}
				Text {
					Layout.fillWidth: true
					text: logDelegate.msg
					color: logDelegate.level === "err" ? "#8a2010" : logDelegate.level === "warn" ? "#7a5a00" : "#4a5060"
					font.pixelSize: 9
					font.family: "Segoe UI"
					elide: Text.ElideRight
				}
			}
		}
	}
}
