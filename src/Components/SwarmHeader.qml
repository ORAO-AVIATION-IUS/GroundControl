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

		Item {
			Layout.fillWidth: true
		}

		// ── Battery: inline mini-battery glyph + readout ──
		RowLayout {
			Layout.alignment: Qt.AlignVCenter
			Layout.rightMargin: 14
			spacing: 7

			// battery glyph
			Item {
				Layout.alignment: Qt.AlignVCenter
				implicitWidth: 24
				implicitHeight: 12

				Rectangle {
					id: battBody
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					width: 21
					height: 12
					radius: 2
					color: "transparent"
					border.width: 1.5
					border.color: S.Style.textMuted

					Rectangle {
						anchors.left: parent.left
						anchors.leftMargin: 2
						anchors.verticalCenter: parent.verticalCenter
						height: parent.height - 4
						width: Math.max(0, (parent.width - 4) * Math.min(100, Math.max(0, root.battery)) / 100)
						radius: 1
						color: root.battery > 50 ? S.Style.success : root.battery > 20 ? S.Style.warning : S.Style.error
					}
				}
				// terminal nub
				Rectangle {
					anchors.left: battBody.right
					anchors.leftMargin: 1
					anchors.verticalCenter: parent.verticalCenter
					width: 2
					height: 5
					radius: 1
					color: S.Style.textMuted
				}
			}

			Text {
				text: root.battery + "%"
				font.pixelSize: 14
				font.bold: true
				font.family: S.Style.fontFamily
				color: root.battery > 50 ? S.Style.textPrimary : root.battery > 20 ? S.Style.warning : S.Style.error
				Layout.alignment: Qt.AlignVCenter
			}
			Text {
				text: root.voltage.toFixed(1) + " V"
				font.pixelSize: 13
				font.family: S.Style.fontFamily
				color: S.Style.textSecondary
				Layout.alignment: Qt.AlignVCenter
			}
		}

		Rectangle {
			Layout.preferredWidth: 1
			Layout.preferredHeight: 20
			color: S.Style.headerDivider
			Layout.alignment: Qt.AlignVCenter
			Layout.rightMargin: 12
		}

		// ── Status: inline dot + armed / in-air state ──
		RowLayout {
			Layout.alignment: Qt.AlignVCenter
			spacing: 7

			Rectangle {
				Layout.alignment: Qt.AlignVCenter
				Layout.preferredWidth: 9
				Layout.preferredHeight: 9
				radius: 4.5
				color: root.inFlight ? S.Style.info : root.armed ? S.Style.success : S.Style.textMuted
			}

			Text {
				text: root.inFlight ? "IN AIR" : root.armed ? "ARMED" : "DISARMED"
				font.pixelSize: 15
				font.bold: true
				font.family: S.Style.fontFamily
				color: root.inFlight ? S.Style.info : root.armed ? S.Style.success : S.Style.textSecondary
				Layout.alignment: Qt.AlignVCenter
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
