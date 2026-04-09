pragma Singleton
import QtQuick 2.6

QtObject {
	// --- Icon Button ---
	readonly property int iconBtnSize: 20           // ← change icon button size from here
	readonly property int iconBtnLabelSize: 8       // ← change icon button label size from here
	readonly property color iconBtnLabelColor: "#cdd6e0"

	// --- Normal Button ---
	readonly property int btnWidth: 64              // ← change normal button size from here
	readonly property int btnHeight: 24
	readonly property color btnColor: "#b2d8ff"
	readonly property color btnHoverColor: "#80bfff"
	readonly property color btnPressedColor: "#0e76ff"
	readonly property color btnTextColor: "black"
	readonly property int btnRadius: 4
	readonly property int btnTextSize: 10

	// --- TelemetryBox ---
	readonly property int boxWidth: 200
	readonly property int boxHeight: 150
	readonly property color boxColor: "#002f55"
	readonly property color boxBorderColor: "#cbc1ff"
	readonly property int boxBorderWidth: 2
	readonly property int boxRadius: 8
	readonly property int boxPadding: 10
}
