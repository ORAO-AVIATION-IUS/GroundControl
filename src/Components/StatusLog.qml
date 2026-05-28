pragma ComponentBehavior: Bound
import Agc.Style as S
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
				color: S.Style.telTitleColor
				font.pixelSize: 9
				font.bold: true
				font.letterSpacing: 1.4
				font.family: S.Style.fontFamily
			}

			Item {
				Layout.fillWidth: true
			}

			Text {
				text: "CLR"
				color: clrArea.containsMouse ? S.Style.textPrimary : S.Style.textMuted
				font.pixelSize: 9
				font.family: S.Style.fontFamily

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
			color: S.Style.separator
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
					color: S.Style.logTimestampColor
					font.pixelSize: 9
					font.family: S.Style.fontFamily
				}
				Text {
					text: "[" + logDelegate.src + "]"
					Layout.preferredWidth: 36
					color: logDelegate.src === "SYS" ? S.Style.logSrcSysColor : S.Style.logSrcOtherColor
					font.pixelSize: 9
					font.bold: true
					font.family: S.Style.fontFamily
				}
				Text {
					Layout.fillWidth: true
					text: logDelegate.msg
					color: logDelegate.level === "err" ? S.Style.logMsgErrorColor : logDelegate.level === "warn" ? S.Style.logMsgWarnColor : S.Style.logMsgColor
					font.pixelSize: 9
					font.family: S.Style.fontFamily
					elide: Text.ElideRight
				}
			}
		}
	}
}
