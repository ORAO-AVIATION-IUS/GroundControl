pragma ComponentBehavior: Bound
import Agc.Style as S
import QtQuick
import QtQuick.Layouts

Item {
	id: root

	property bool armed: false
	property bool inFlight: false
	property bool connected: false
	property string flightMode: ""
	property string droneId: "--"

	signal armClicked
	signal disarmClicked
	signal takeoffClicked
	signal landClicked
	signal rthClicked

	component ActBtn: Rectangle {
		id: actBtn

		property string label: ""
		property color bgColor: S.Style.controlActionBg
		property color bgColorHover: S.Style.controlActionBgHover
		property color txtColor: S.Style.textPrimary
		property color borderColor: S.Style.controlActionBorder
		property bool highlight: false
		signal tapped

		Layout.fillWidth: true
		Layout.preferredHeight: 26
		radius: 0
		color: !enabled ? Qt.darker(actBtn.bgColor, 0.92) : ma.pressed ? Qt.darker(actBtn.bgColor, 1.12) : ma.containsMouse ? actBtn.bgColorHover : actBtn.bgColor
		border.color: actBtn.highlight ? S.Style.borderFocus : actBtn.borderColor
		border.width: 1
		opacity: enabled ? 1.0 : 0.4

		Text {
			anchors.centerIn: parent
			text: actBtn.label
			color: actBtn.txtColor
			font.pixelSize: 11
			font.bold: true
			font.family: S.Style.fontFamily
		}

		MouseArea {
			id: ma
			anchors.fill: parent
			hoverEnabled: true
			onClicked: if (actBtn.enabled)
				parent.tapped()
		}
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.top: parent.top
		anchors.margins: 12
		spacing: 0

		Text {
			text: "CONTROLS"
			color: S.Style.telTitleColor
			font.pixelSize: 9
			font.bold: true
			font.letterSpacing: 1.4
			font.family: S.Style.fontFamily
			Layout.bottomMargin: 6
		}

		GridLayout {
			Layout.fillWidth: true
			columns: 2
			rowSpacing: 3
			columnSpacing: 3

			ActBtn {
				label: "ARM"
				bgColor: S.Style.controlArmBg
				bgColorHover: S.Style.controlArmBgHover
				txtColor: S.Style.controlArmText
				borderColor: S.Style.controlArmBorder
				enabled: root.connected && !root.armed
				onTapped: root.armClicked()
			}
			ActBtn {
				label: "DISARM"
				bgColor: S.Style.controlDisarmBg
				bgColorHover: S.Style.controlDisarmBgHover
				txtColor: S.Style.controlDisarmText
				borderColor: S.Style.controlDisarmBorder
				enabled: root.connected && root.armed && !root.inFlight
				onTapped: root.disarmClicked()
			}
			ActBtn {
				label: "TAKEOFF"
				bgColor: S.Style.controlActionBg
				bgColorHover: S.Style.controlActionBgHover
				txtColor: S.Style.info
				borderColor: S.Style.borderDefault
				enabled: root.connected && root.armed && !root.inFlight
				onTapped: root.takeoffClicked()
			}
			ActBtn {
				label: "LAND"
				bgColor: S.Style.controlActionBg
				bgColorHover: S.Style.controlActionBgHover
				txtColor: S.Style.warning
				borderColor: S.Style.borderDefault
				enabled: root.connected && root.inFlight
				onTapped: root.landClicked()
			}
			ActBtn {
				label: "RTH"
				bgColor: S.Style.controlActionBg
				bgColorHover: S.Style.controlActionBgHover
				txtColor: S.Style.info
				borderColor: S.Style.borderDefault
				enabled: root.connected && root.inFlight
				onTapped: root.rthClicked()
			}
		}

		Rectangle {
			Layout.fillWidth: true
			Layout.preferredHeight: 1
			color: S.Style.separator
			Layout.topMargin: 10
			Layout.bottomMargin: 10
		}

		Text {
			text: "FLIGHT MODE"
			color: S.Style.telTitleColor
			font.pixelSize: 9
			font.bold: true
			font.letterSpacing: 1.4
			font.family: S.Style.fontFamily
			Layout.bottomMargin: 6
		}

		Rectangle {
			Layout.fillWidth: true
			Layout.preferredHeight: 26
			radius: 0
			color: S.Style.controlFlightModeBg
			border.color: S.Style.controlFlightModeBorder
			border.width: 1

			Text {
				anchors.centerIn: parent
				text: root.flightMode || "UNKNOWN"
				color: S.Style.controlFlightModeText
				font.pixelSize: 11
				font.bold: true
				font.family: S.Style.fontFamily
			}
		}

		Item {
			Layout.fillHeight: true
		}
	}
}
