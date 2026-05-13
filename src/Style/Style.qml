pragma Singleton
import QtQuick

QtObject {
	// --- Icon Button ---
	readonly property int iconBtnSize: 28
	readonly property int iconBtnLabelSize: 10
	readonly property color iconBtnLabelColor: "#cdd6e0"
	readonly property int iconBtnPadding: 4
	readonly property int iconBtnRadius: 3
	readonly property color iconBtnCheckedBg: "#2a5298"
	readonly property color iconBtnCheckedLabelColor: "#8cb4f0"
	readonly property color iconBtnHighlightBg: "#1e3a5f"
	readonly property color iconBtnHoverBg: "#2a2f3a"
	readonly property color iconBtnPressedBg: "#3a4050"

	// --- Button Group Section ---
	readonly property color sectionBgColor: "#1c1f26"
	readonly property int sectionRadius: 5
	readonly property int sectionPadding: 10
	readonly property int sectionSpacing: 6
	readonly property color sectionLabelColor: "#6b7a8d"
	readonly property int sectionLabelSize: 7
	readonly property int sectionRowSpacing: 10

	// --- Map Panel Overlay ---
	readonly property int overlayMargin: 6

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
