pragma Singleton
import QtQuick

QtObject {
	// --- ToolButton Styles ---
	readonly property int iconBtnWidth: 24
	readonly property int iconBtnHeight: 24

	// --- NormalButton Styles ---
	readonly property int btnWidth: 64
	readonly property int btnHeight: 24
	readonly property color btnColor: "#b2d8ff"
	readonly property color btnHoverColor: "#80bfff"
	readonly property color btnPressedColor: "#0e76ff"
	readonly property color btnTextColor: "black"
	readonly property int btnRadius: 4
	readonly property int btnTextSize: 10

	// --- TelemetryBox Styles ---
	readonly property int boxWidth: 200
	readonly property int boxHeight: 150
	readonly property color boxColor: "#002f55"
	readonly property color boxBorderColor: "#cbc1ff"
	readonly property int boxBorderWidth: 2
	readonly property int boxRadius: 8
	readonly property int boxPadding: 10
}
