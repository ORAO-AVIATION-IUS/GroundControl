import Agc.Style as S
import QtQuick
import QtQuick.Layouts

Rectangle {
	id: root

	property string droneId: "M1"
	property string flightMode: "STBY"
	property bool armed: false
	property bool selected: false
	property double pitch: 0
	property double roll: 0
	property double altitude: 0
	property double groundspeed: 0
	property int battery: 100
	property int gpsCount: 0
	property int gpsFix: 0   // 0=no fix  1=2D  2=3D
	property bool sysHealth: true

	signal armRequested
	signal disarmRequested
	signal selectRequested

	color: selected ? S.Style.cardBgSelected : S.Style.cardBg
	border.color: selected ? S.Style.cardBorderSelected : (armed ? S.Style.cardBorderArmed : S.Style.cardBorderDefault)
	border.width: selected ? 2 : 1
	radius: 8

	MouseArea {
		anchors.fill: parent
		onClicked: root.selectRequested()
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 6
		spacing: 3

		RowLayout {
			Layout.fillWidth: true
			spacing: 5

			Rectangle {
				Layout.preferredWidth: 8
				Layout.preferredHeight: 8
				radius: 4
				color: root.armed ? S.Style.success : S.Style.error
				Behavior on color {
					ColorAnimation {
						duration: 300
					}
				}
			}

			Text {
				text: root.droneId
				color: S.Style.cardTextId
				font.pixelSize: 12
				font.bold: true
				font.family: S.Style.fontFamilyMono
			}

			Item {
				Layout.fillWidth: true
			}

			Rectangle {
				Layout.preferredHeight: 14
				Layout.preferredWidth: modeLabel.implicitWidth + 10
				radius: 3
				color: S.Style.cardModeBg
				border.color: S.Style.cardModeBorder
				border.width: 1

				Text {
					id: modeLabel
					anchors.centerIn: parent
					text: root.flightMode
					color: S.Style.cardModeText
					font.pixelSize: 8
					font.bold: true
					font.family: S.Style.fontFamilyMono
				}
			}

			// sys-health dot: blue=ok  red=fault
			Rectangle {
				Layout.preferredWidth: 6
				Layout.preferredHeight: 6
				radius: 3
				color: root.sysHealth ? S.Style.info : S.Style.error
				opacity: 0.85
			}
		}

		AttitudeIndicator {
			Layout.alignment: Qt.AlignHCenter
			Layout.preferredWidth: Math.min(root.width - 16, 96)
			Layout.preferredHeight: Math.min(root.width - 16, 96)
			pitch: root.pitch
			roll: root.roll
		}

		Grid {
			Layout.fillWidth: true
			columns: 4
			spacing: 2

			Text {
				text: "ALT"
				color: S.Style.cardTextLabel
				font.pixelSize: 8
			}
			Text {
				text: root.altitude.toFixed(0) + "m"
				color: S.Style.cardTextValue
				font.pixelSize: 8
				width: (root.width - 28) / 2
				elide: Text.ElideRight
			}
			Text {
				text: "SPD"
				color: S.Style.cardTextLabel
				font.pixelSize: 8
			}
			Text {
				text: root.groundspeed.toFixed(1) + "m/s"
				color: S.Style.cardTextValue
				font.pixelSize: 8
			}

			Text {
				text: "BAT"
				color: S.Style.cardTextLabel
				font.pixelSize: 8
			}
			Text {
				text: root.battery + "%"
				color: root.battery > 50 ? S.Style.success : root.battery > 20 ? S.Style.warning : S.Style.error
				font.pixelSize: 8
			}
			Text {
				text: "GPS"
				color: S.Style.cardTextLabel
				font.pixelSize: 8
			}
			Text {
				text: root.gpsCount + (root.gpsFix === 2 ? "/3D" : root.gpsFix === 1 ? "/2D" : "/--")
				color: root.gpsFix === 2 ? S.Style.success : root.gpsFix === 1 ? S.Style.warning : S.Style.error
				font.pixelSize: 8
			}
		}

		RowLayout {
			Layout.fillWidth: true
			spacing: 4

			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: 20
				radius: 3
				color: armArea.pressed ? S.Style.cardArmBgPressed : armArea.containsMouse ? S.Style.cardArmBgHover : S.Style.cardArmBg
				border.color: root.armed ? S.Style.borderDefault : S.Style.controlArmBorder
				border.width: 1
				opacity: root.armed ? 0.3 : 1.0

				Text {
					anchors.centerIn: parent
					text: "ARM"
					color: S.Style.cardArmText
					font.pixelSize: 9
					font.bold: true
					font.family: S.Style.fontFamilyMono
				}

				MouseArea {
					id: armArea
					anchors.fill: parent
					hoverEnabled: true
					enabled: !root.armed
					onClicked: mouse => {
						mouse.accepted = true;
						root.armRequested();
					}
				}
			}

			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: 20
				radius: 3
				color: disarmArea.pressed ? S.Style.cardDisarmBgPressed : disarmArea.containsMouse ? S.Style.cardDisarmBgHover : S.Style.cardDisarmBg
				border.color: root.armed ? S.Style.controlDisarmBorder : S.Style.borderDefault
				border.width: 1
				opacity: root.armed ? 1.0 : 0.3

				Text {
					anchors.centerIn: parent
					text: "DISARM"
					color: S.Style.cardDisarmText
					font.pixelSize: 9
					font.bold: true
					font.family: S.Style.fontFamilyMono
				}

				MouseArea {
					id: disarmArea
					anchors.fill: parent
					hoverEnabled: true
					enabled: root.armed
					onClicked: mouse => {
						mouse.accepted = true;
						root.disarmRequested();
					}
				}
			}
		}
	}
}
