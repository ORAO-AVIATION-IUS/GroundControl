pragma Singleton
import QtQuick 2.6

QtObject {
	// --- Global dark palette ---
	readonly property color bgColor: "#1e2126"
	readonly property color bgLightColor: "#25282d"
	readonly property color bgMidColor: "#2a2d32"
	readonly property color surfaceColor: "#303338"
	readonly property color borderColor: "#3a3d42"
	readonly property color textColor: "#cdd6e0"
	readonly property color textMutedColor: "#6b7a8d"

	// --- Icon Button ---
	readonly property int iconBtnSize: 20
	readonly property int iconBtnLabelSize: 8
	readonly property color iconBtnLabelColor: "#cdd6e0"

	// --- Normal Button ---
	readonly property int btnWidth: 64
	readonly property int btnHeight: 24
	readonly property color btnColor: "#303338"
	readonly property color btnHoverColor: "#3a3d42"
	readonly property color btnPressedColor: "#0e76ff"
	readonly property color btnTextColor: "#cdd6e0"
	readonly property int btnRadius: 4
	readonly property int btnTextSize: 10

	// --- TelemetryBox ---
	readonly property int boxWidth: 200
	readonly property int boxHeight: 150
	readonly property color boxColor: "#1a1d22"
	readonly property color boxBorderColor: "#3a3d42"
	readonly property int boxBorderWidth: 1
	readonly property int boxRadius: 8
	readonly property int boxPadding: 10
}
