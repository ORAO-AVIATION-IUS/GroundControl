import Agc.Style as S
import QtQuick
import QtQuick.Layouts

Item {
	id: root
	height: 44

	property string droneId: "--"
	property string flightMode: ""
	property bool readyToFly: false
	property bool armed: false
	property bool inFlight: false
	property int battery: 0
	property real voltage: 0.0

	RowLayout {
		anchors.fill: parent
		anchors.leftMargin: 14
		anchors.rightMargin: 14
		spacing: 0

		Text {
			text: root.droneId
			font.pixelSize: 15
			font.bold: true
			font.family: S.Style.fontFamily
			color: S.Style.textPrimary
			Layout.alignment: Qt.AlignVCenter
		}

		Rectangle {
			Layout.preferredWidth: 1
			Layout.preferredHeight: 20
			color: S.Style.headerDivider
			Layout.alignment: Qt.AlignVCenter
			Layout.leftMargin: 12
			Layout.rightMargin: 12
		}

		Text {
			text: root.readyToFly ? "Ready To Fly" : "Not Ready"
			font.pixelSize: 15
			font.bold: true
			font.family: S.Style.fontFamily
			color: root.readyToFly ? S.Style.success : S.Style.error
			Layout.alignment: Qt.AlignVCenter
		}

		Rectangle {
			Layout.preferredWidth: 1
			Layout.preferredHeight: 20
			color: S.Style.headerDivider
			Layout.alignment: Qt.AlignVCenter
			Layout.leftMargin: 12
			Layout.rightMargin: 12
		}

		Text {
			text: root.flightMode || "UNKNOWN"
			font.pixelSize: 15
			font.bold: true
			font.family: S.Style.fontFamily
			color: S.Style.textAccent
			Layout.alignment: Qt.AlignVCenter
		}

		Rectangle {
			Layout.preferredWidth: 1
			Layout.preferredHeight: 20
			color: S.Style.headerDivider
			Layout.alignment: Qt.AlignVCenter
			Layout.leftMargin: 12
			Layout.rightMargin: 12
		}

		Text {
			text: root.inFlight ? "IN AIR" : root.armed ? "ARMED" : "DISARMED"
			font.pixelSize: 15
			font.bold: true
			font.family: S.Style.fontFamily
			color: root.inFlight ? S.Style.info : root.armed ? S.Style.success : S.Style.textSecondary
			Layout.alignment: Qt.AlignVCenter
		}

		Item {
			Layout.fillWidth: true
		}

		Rectangle {
			Layout.alignment: Qt.AlignVCenter
			Layout.rightMargin: 6
			Layout.preferredWidth: 76
			Layout.preferredHeight: 30
			radius: 0
			color: S.Style.bgSection
			border.color: S.Style.borderDefault
			border.width: 1

			Rectangle {
				width: 3
				height: parent.height
				radius: 0
				color: root.battery > 50 ? S.Style.success : root.battery > 20 ? S.Style.warning : S.Style.error
			}

			Column {
				anchors.left: parent.left
				anchors.leftMargin: 9
				anchors.verticalCenter: parent.verticalCenter
				spacing: 1

				Text {
					text: "BATTERY"
					font.pixelSize: 8
					font.family: S.Style.fontFamily
					color: S.Style.textMuted
				}
				Text {
					text: root.battery + "%  " + root.voltage.toFixed(1) + " V"
					font.pixelSize: 9
					font.bold: true
					font.family: S.Style.fontFamily
					color: S.Style.textPrimary
				}
			}
		}

		Rectangle {
			Layout.alignment: Qt.AlignVCenter
			Layout.rightMargin: 12
			Layout.preferredWidth: 76
			Layout.preferredHeight: 30
			radius: 0
			color: S.Style.bgSection
			border.color: root.armed ? S.Style.success : S.Style.borderDefault
			border.width: 1

			Rectangle {
				width: 3
				height: parent.height
				radius: 0
				color: root.armed ? S.Style.success : S.Style.textMuted
			}

			Column {
				anchors.left: parent.left
				anchors.leftMargin: 9
				anchors.verticalCenter: parent.verticalCenter
				spacing: 1

				Text {
					text: "STATUS"
					font.pixelSize: 8
					font.family: S.Style.fontFamily
					color: S.Style.textMuted
				}
				Text {
					text: root.armed ? "ARMED" : "DISARMED"
					font.pixelSize: 9
					font.bold: true
					font.family: S.Style.fontFamily
					color: root.armed ? S.Style.success : S.Style.textSecondary
				}
			}
		}
	}

	Rectangle {
		anchors.bottom: parent.bottom
		width: parent.width
		height: 1
		color: S.Style.headerDivider
	}
}
