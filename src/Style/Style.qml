pragma Singleton
import QtQuick

QtObject {
	// ─── Typography ────────────────────────────────────────────
	readonly property string fontFamily: "Segoe UI"
	readonly property string fontFamilyMono: "Courier New"

	// ─── Base Surface Colors ───────────────────────────────────
	readonly property color bgWindow: "#0d1117"
	readonly property color bgPanel: "#161b22"
	readonly property color bgSection: "#1c2128"
	readonly property color bgElevated: "#21262d"
	readonly property color bgHover: "#292e36"
	readonly property color bgPressed: "#313840"

	// ─── Text Colors ───────────────────────────────────────────
	readonly property color textPrimary: "#e6edf3"
	readonly property color textSecondary: "#8b949e"
	readonly property color textMuted: "#6e7681"
	readonly property color textAccent: "#58a6ff"
	readonly property color textInverse: "#0d1117"

	// ─── Borders & Separators ──────────────────────────────────
	readonly property color borderDefault: "#30363d"
	readonly property color borderLight: "#21262d"
	readonly property color borderFocus: "#58a6ff"
	readonly property color separator: "#21262d"

	// ─── Status Colors ─────────────────────────────────────────
	readonly property color success: "#3fb950"
	readonly property color warning: "#d29922"
	readonly property color error: "#f85149"
	readonly property color info: "#58a6ff"

	// ─── Mission / per-drone plan colors ───────────────────────
	// Shared so the map overlay and the drone-panel waypoint list pick the
	// same color for a given drone index.
	readonly property var missionColors: ["#ff9d00", "#00d0ff", "#c77dff", "#6bffb8", "#ff6b9a", "#ffd06b", "#7aa7ff", "#ff7a45"]
	function missionColor(index) {
		return missionColors[Math.max(0, index) % missionColors.length];
	}

	// ─── Semantic: Icon Button ─────────────────────────────────
	readonly property int iconBtnSize: 28
	readonly property int iconBtnLabelSize: 10
	readonly property color iconBtnLabelColor: textSecondary
	readonly property int iconBtnPadding: 4
	readonly property int iconBtnRadius: 3
	readonly property color iconBtnCheckedBg: "#1f6feb"
	readonly property color iconBtnCheckedLabelColor: "#ffffff"
	readonly property color iconBtnHighlightBg: "#1f6feb40"
	readonly property color iconBtnHoverBg: bgHover
	readonly property color iconBtnPressedBg: bgPressed

	// ─── Semantic: Button Group / Section ──────────────────────
	readonly property color sectionBgColor: bgSection
	readonly property int sectionRadius: 5
	readonly property int sectionPadding: 10
	readonly property int sectionSpacing: 6
	readonly property color sectionLabelColor: textMuted
	readonly property int sectionLabelSize: 7
	readonly property int sectionRowSpacing: 10

	// ─── Semantic: Map Overlay ─────────────────────────────────
	readonly property int overlayMargin: 6

	// ─── Semantic: Default Button ──────────────────────────────
	readonly property int btnWidth: 64
	readonly property int btnHeight: 24
	readonly property color btnColor: "#1f6feb"
	readonly property color btnHoverColor: "#388bfd"
	readonly property color btnPressedColor: "#1a5cc7"
	readonly property color btnTextColor: "#ffffff"
	readonly property int btnRadius: 4
	readonly property int btnTextSize: 10

	// ─── Semantic: Telemetry Box ───────────────────────────────
	readonly property int boxWidth: 200
	readonly property int boxHeight: 150
	readonly property color boxColor: bgSection
	readonly property color boxBorderColor: borderDefault
	readonly property int boxBorderWidth: 1
	readonly property int boxRadius: 8
	readonly property int boxPadding: 10

	// ─── Semantic: Panel Header ────────────────────────────────
	readonly property color headerBg: bgPanel
	readonly property color headerBorder: borderDefault
	readonly property color headerText: textPrimary
	readonly property color headerLabel: textSecondary
	readonly property color headerDivider: borderDefault

	// ─── Semantic: Controls ────────────────────────────────────
	readonly property color controlArmBg: "#0d2818"
	readonly property color controlArmBgHover: "#122e1c"
	readonly property color controlArmBorder: "#238636"
	readonly property color controlArmText: success
	readonly property color controlDisarmBg: "#2d1215"
	readonly property color controlDisarmBgHover: "#3d1a1e"
	readonly property color controlDisarmBorder: "#da3633"
	readonly property color controlDisarmText: error
	readonly property color controlActionBg: "#1c2333"
	readonly property color controlActionBgHover: "#22293a"
	readonly property color controlActionBorder: borderDefault
	readonly property color controlFlightModeBg: "#1c2333"
	readonly property color controlFlightModeBorder: info
	readonly property color controlFlightModeText: info

	// ─── Semantic: Telemetry Sidebar ───────────────────────────
	readonly property color telLabelColor: textSecondary
	readonly property color telValueColor: textPrimary
	readonly property color telWarnColor: warning
	readonly property color telTitleColor: textMuted

	// ─── Semantic: Status Log ──────────────────────────────────
	readonly property color logTimestampColor: textMuted
	readonly property color logSrcSysColor: info
	readonly property color logSrcOtherColor: warning
	readonly property color logMsgColor: textSecondary
	readonly property color logMsgErrorColor: error
	readonly property color logMsgWarnColor: warning

	// ─── Semantic: Drone Card ──────────────────────────────────
	readonly property color cardBg: "#0c1522"
	readonly property color cardBgSelected: "#131e30"
	readonly property color cardBorderSelected: "#1f6feb"
	readonly property color cardBorderArmed: "#238636"
	readonly property color cardBorderDefault: borderDefault
	readonly property color cardTextId: textAccent
	readonly property color cardTextLabel: textMuted
	readonly property color cardTextValue: textPrimary
	readonly property color cardModeBg: bgWindow
	readonly property color cardModeBorder: borderDefault
	readonly property color cardModeText: textAccent
	readonly property color cardArmBg: "#00210d"
	readonly property color cardArmBgHover: "#003815"
	readonly property color cardArmBgPressed: "#004d1e"
	readonly property color cardArmText: success
	readonly property color cardDisarmBg: "#220800"
	readonly property color cardDisarmBgHover: "#380e00"
	readonly property color cardDisarmBgPressed: "#4d1400"
	readonly property color cardDisarmText: error
}
