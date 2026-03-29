pragma Singleton
import QtQuick 2.6

QtObject {
	// --- ToolButton Styles (Armed, Camera, Edit, etc.) ---
	readonly property int toolButtonWidth: 24
	readonly property int toolButtonHeight: 24

	// --- NormalButton Styles ---
	readonly property int normalButtonWidth: 64
	readonly property int normalButtonHeight: 24
	readonly property color normalButtonColor: "#b2d8ff"
	readonly property color normalButtonHoverColor: "#80bfff"
	readonly property color normalButtonPressedColor: "#0e76ff"
	readonly property color normalButtonTextColor: "black"
	readonly property int normalButtonRadius: 4
	readonly property int normalButtonTextSize: 10

	// --- TelemetryBox Styles ---
	readonly property int boxWidth: 200
	readonly property int boxHeight: 150
	readonly property color boxColor: "#002f55"
	readonly property color boxBorderColor: "#cbc1ff"
	readonly property int boxBorderWidth: 2
	readonly property int boxRadius: 8
	readonly property int boxPadding: 10
}
