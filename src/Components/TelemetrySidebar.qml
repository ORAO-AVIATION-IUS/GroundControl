import QtQuick
import QtQuick.Layouts

Item {
	id: root

	property real roll: 0.0
	property real pitch: 0.0
	property real yaw: 0.0
	property real altRel: 0.0
	property real climbRate: 0.0
	property real groundspeed: 0.0
	property real heading: 0.0
	property int battery: 0
	property real voltage: 0.0
	property int ping: 0

	component TelRow: RowLayout {
		id: telRow

		property string lbl: ""
		property string val: ""
		property bool warn: false

		Layout.fillWidth: true
		spacing: 0

		Text {
			text: telRow.lbl
			color: "#9090a0"
			font.pixelSize: 10
			font.family: "Segoe UI"
			Layout.preferredWidth: 46
		}
		Text {
			text: telRow.val
			Layout.fillWidth: true
			color: telRow.warn ? "#7a5a00" : "#1a1a2e"
			font.pixelSize: 10
			font.family: "Segoe UI"
			horizontalAlignment: Text.AlignRight
		}
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 10
		anchors.topMargin: 10
		spacing: 3

		Text {
			text: "TELEMETRY"
			color: "#a0a8b0"
			font.pixelSize: 9
			font.bold: true
			font.letterSpacing: 1.4
			font.family: "Segoe UI"
			Layout.bottomMargin: 4
		}

		TelRow {
			lbl: "ROLL"
			val: root.roll.toFixed(1) + " °"
		}
		TelRow {
			lbl: "PITCH"
			val: root.pitch.toFixed(1) + " °"
		}
		TelRow {
			lbl: "YAW"
			val: root.yaw.toFixed(1) + " °"
		}
		TelRow {
			lbl: "ALT"
			val: root.altRel.toFixed(1) + " m"
		}
		TelRow {
			lbl: "CLIMB"
			val: root.climbRate.toFixed(1) + " m/s"
		}
		TelRow {
			lbl: "GSPD"
			val: root.groundspeed.toFixed(1) + " m/s"
		}
		TelRow {
			lbl: "HDG"
			val: root.heading.toFixed(1) + " °"
		}
		TelRow {
			lbl: "BAT"
			val: root.battery + " %"
			warn: root.battery < 20
		}
		TelRow {
			lbl: "VOLT"
			val: root.voltage.toFixed(2) + " V"
			warn: root.voltage < 11.0
		}
		TelRow {
			lbl: "PING"
			val: root.ping + " ms"
			warn: root.ping > 200
		}

		Item {
			Layout.fillHeight: true
		}
	}
}
