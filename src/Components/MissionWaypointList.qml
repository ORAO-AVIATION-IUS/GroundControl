pragma ComponentBehavior: Bound

import Agc.Style as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// MissionWaypointList - shows the active mission plan as a connected waypoint
// list, highlighting the waypoint the drone is currently flying to, the plan
// completion progress, and a compact start / pause / restart control.
Item {
	id: root

	// Plan waypoints (QVariantList from MissionPlanModel.items).
	property var items: []
	// Index of the waypoint the drone is currently heading to (0-based).
	property int currentWp: -1
	// Number of waypoints in the uploaded mission (vehicle side).
	property int totalWp: 0

	property bool running: false
	property bool paused: false
	property bool finished: false
	property bool uploaded: false
	property bool dirty: false
	property bool busy: false
	property bool connected: false
	property bool readyToFly: false
	property string busyText: ""
	property string errorText: ""

	// End-of-mission action flags (shown as a badge on the last waypoint).
	property bool returnHome: false
	property bool landAtEnd: false
	// Plan default speed; per-waypoint speed is shown only when it differs.
	property real defaultSpeed: 0
	// This drone's plan color (matches the map overlay). Done waypoints use the
	// success color instead.
	property color accentColor: S.Style.info

	signal startClicked
	signal pauseClicked
	signal restartClicked

	readonly property int _listCount: root.items ? root.items.length : 0
	readonly property int _total: root.totalWp > 0 ? root.totalWp : root._listCount
	readonly property int _done: root.running || root.paused || root.finished ? Math.max(0, Math.min(root.currentWp, root._total)) : 0
	readonly property real _progress: root.finished ? 1 : (root._total > 0 ? root._done / root._total : 0)

	function _cmdLabel(modelData, index) {
		const cmd = modelData && modelData.command ? modelData.command : "waypoint";
		if (cmd === "takeoff")
			return "TAKEOFF";
		if (cmd === "land")
			return "LAND";
		return "WP " + (index + 1);
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 12
		spacing: 0

		// ── Header: title + waypoint counter ──
		RowLayout {
			Layout.fillWidth: true
			spacing: 6

			Text {
				text: "MISSION PLAN"
				color: S.Style.telTitleColor
				font.pixelSize: 9
				font.bold: true
				font.letterSpacing: 1.4
				font.family: S.Style.fontFamily
			}

			Item {
				Layout.fillWidth: true
			}

			Text {
				text: root._done + " / " + root._total
				color: S.Style.textSecondary
				font.pixelSize: 10
				font.bold: true
				font.family: S.Style.fontFamilyMono
			}
		}

		// ── Control + progress bar (compact, single row) ──
		RowLayout {
			Layout.fillWidth: true
			Layout.topMargin: 8
			spacing: 8
			visible: root._listCount > 0

			// Single compact action button to the left of the progress bar.
			Rectangle {
				id: ctrlBtn

				// "start" | "pause" | "restart"
				readonly property string mode: root.finished ? "restart" : root.running ? "pause" : "start"
				readonly property color accent: ctrlBtn.mode === "pause" ? S.Style.warning : ctrlBtn.mode === "restart" ? S.Style.info : S.Style.success
				readonly property bool actionEnabled: {
					if (ctrlBtn.mode === "pause")
						return !root.busy;
					if (ctrlBtn.mode === "restart")
						return root.connected && !root.busy;
					return root.connected && root.readyToFly && root.uploaded && !root.dirty && !root.busy;
				}

				Layout.preferredWidth: 28
				Layout.preferredHeight: 28
				radius: 4
				color: !ctrlBtn.actionEnabled ? S.Style.bgElevated : ctrlMa.pressed ? Qt.darker(ctrlBtn.accent, 2.2) : ctrlMa.containsMouse ? Qt.darker(ctrlBtn.accent, 2.6) : S.Style.controlActionBg
				border.color: ctrlBtn.actionEnabled ? ctrlBtn.accent : S.Style.borderDefault
				border.width: 1
				opacity: ctrlBtn.actionEnabled ? 1.0 : 0.45

				Text {
					anchors.centerIn: parent
					text: ctrlBtn.mode === "pause" ? "❚❚" : ctrlBtn.mode === "restart" ? "↺" : "▶"
					color: ctrlBtn.actionEnabled ? ctrlBtn.accent : S.Style.textMuted
					font.pixelSize: ctrlBtn.mode === "pause" ? 11 : 13
					font.bold: true
					font.family: S.Style.fontFamily
				}

				MouseArea {
					id: ctrlMa
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: ctrlBtn.actionEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
					onClicked: {
						if (!ctrlBtn.actionEnabled)
							return;
						if (ctrlBtn.mode === "pause")
							root.pauseClicked();
						else if (ctrlBtn.mode === "restart")
							root.restartClicked();
						else
							root.startClicked();
					}
				}

				ToolTip.visible: ctrlMa.containsMouse
				ToolTip.text: ctrlBtn.mode === "pause" ? qsTr("Pause mission") : ctrlBtn.mode === "restart" ? qsTr("Restart mission") : root.paused ? qsTr("Resume mission") : qsTr("Start mission")
			}

			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: 4
				radius: 2
				color: S.Style.bgElevated

				Rectangle {
					width: parent.width * root._progress
					height: parent.height
					radius: 2
					color: root.finished ? S.Style.success : root.running ? S.Style.info : root.paused ? S.Style.warning : S.Style.success
					Behavior on width {
						NumberAnimation {
							duration: 250
							easing.type: Easing.OutCubic
						}
					}
				}
			}
		}

		// ── Status line ──
		Text {
			Layout.fillWidth: true
			Layout.topMargin: 6
			text: {
				if (root.busy && root.busyText !== "")
					return root.busyText;
				if (root.errorText !== "")
					return root.errorText;
				if (root._listCount === 0)
					return "No mission planned";
				if (root.finished)
					return "Mission complete";
				if (!root.uploaded || root.dirty)
					return "Upload plan from map to fly";
				if (root.running)
					return Math.round(root._progress * 100) + "% complete";
				if (root.paused)
					return "Paused · " + Math.round(root._progress * 100) + "% complete";
				return "Ready to start";
			}
			color: root.errorText !== "" ? S.Style.error : S.Style.textMuted
			font.pixelSize: 10
			font.family: S.Style.fontFamily
			elide: Text.ElideRight
		}

		Rectangle {
			Layout.fillWidth: true
			Layout.preferredHeight: 1
			color: S.Style.separator
			Layout.topMargin: 10
			Layout.bottomMargin: 2
		}

		// ── Waypoint list ──
		ListView {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.topMargin: 4
			clip: true
			model: root.items
			spacing: 0
			boundsBehavior: Flickable.StopAtBounds

			ScrollBar.vertical: ScrollBar {
				policy: ScrollBar.AsNeeded
			}

			delegate: Rectangle {
				id: wpRow

				required property int index
				required property var modelData

				readonly property bool active: root.running || root.paused || root.finished
				readonly property bool isCurrent: wpRow.active && !root.finished && root.currentWp === wpRow.index
				readonly property bool isDone: root.finished || (wpRow.active && wpRow.index < root.currentWp)
				readonly property bool isLast: wpRow.index === root._listCount - 1
				readonly property color nodeColor: wpRow.isDone ? S.Style.success : root.accentColor

				// per-waypoint extra info
				readonly property bool showSpeed: wpRow.modelData && wpRow.modelData.speedEnabled === true && wpRow.modelData.speed !== undefined && Math.abs(wpRow.modelData.speed - root.defaultSpeed) > 0.05
				readonly property bool showLoiter: wpRow.modelData && wpRow.modelData.loiterEnabled === true && wpRow.modelData.loiter > 0
				readonly property string endBadge: wpRow.isLast ? (root.returnHome ? "RTL" : root.landAtEnd ? "LAND" : "") : ""

				width: ListView.view ? ListView.view.width : 0
				height: 36
				color: wpRow.isCurrent ? Qt.rgba(0.12, 0.43, 0.92, 0.16) : "transparent"

				RowLayout {
					anchors.fill: parent
					anchors.rightMargin: 4
					spacing: 8

					// ── Connected node marker column ──
					Item {
						Layout.preferredWidth: 22
						Layout.fillHeight: true

						// connector to previous node (top half)
						Rectangle {
							anchors.horizontalCenter: parent.horizontalCenter
							anchors.top: parent.top
							height: parent.height / 2
							width: 2
							visible: wpRow.index > 0
							color: (wpRow.active && wpRow.index <= root.currentWp && !root.finished) || root.finished ? S.Style.success : root.accentColor
							opacity: 0.85
						}
						// connector to next node (bottom half)
						Rectangle {
							anchors.horizontalCenter: parent.horizontalCenter
							anchors.bottom: parent.bottom
							height: parent.height / 2
							width: 2
							visible: !wpRow.isLast
							color: (wpRow.active && (wpRow.index + 1) <= root.currentWp && !root.finished) || root.finished ? S.Style.success : root.accentColor
							opacity: 0.85
						}

						// node
						Rectangle {
							anchors.centerIn: parent
							width: wpRow.isCurrent ? 14 : 11
							height: width
							radius: width / 2
							color: wpRow.isCurrent ? Qt.rgba(0.12, 0.43, 0.92, 1.0) : wpRow.isDone ? S.Style.success : S.Style.bgPanel
							border.color: wpRow.nodeColor
							border.width: 2

							Text {
								anchors.centerIn: parent
								visible: wpRow.isDone
								text: "✓"
								color: S.Style.bgWindow
								font.pixelSize: 8
								font.bold: true
							}
						}
					}

					// ── Label + meta ──
					ColumnLayout {
						Layout.fillWidth: true
						spacing: 1

						Text {
							text: root._cmdLabel(wpRow.modelData, wpRow.index)
							color: wpRow.isCurrent ? S.Style.textPrimary : wpRow.isDone ? S.Style.textMuted : S.Style.textSecondary
							font.pixelSize: 11
							font.bold: wpRow.isCurrent
							font.family: S.Style.fontFamily
							Layout.fillWidth: true
							elide: Text.ElideRight
						}

						RowLayout {
							Layout.fillWidth: true
							spacing: 6
							visible: wpRow.showSpeed || wpRow.showLoiter || wpRow.endBadge !== ""

							Text {
								visible: wpRow.showSpeed
								text: "▸ " + wpRow.modelData.speed.toFixed(1) + " m/s"
								color: S.Style.textMuted
								font.pixelSize: 9
								font.family: S.Style.fontFamilyMono
							}
							Text {
								visible: wpRow.showLoiter
								text: "⟳ " + wpRow.modelData.loiter.toFixed(0) + " s"
								color: S.Style.textMuted
								font.pixelSize: 9
								font.family: S.Style.fontFamilyMono
							}
							Text {
								visible: wpRow.endBadge !== ""
								text: (root.returnHome ? "⌂ " : "▾ ") + wpRow.endBadge
								color: S.Style.warning
								font.pixelSize: 9
								font.bold: true
								font.family: S.Style.fontFamily
							}
							Item {
								Layout.fillWidth: true
							}
						}
					}

					Text {
						text: wpRow.modelData && wpRow.modelData.altitude !== undefined ? wpRow.modelData.altitude.toFixed(0) + " m" : ""
						color: wpRow.isCurrent ? S.Style.textSecondary : S.Style.textMuted
						font.pixelSize: 10
						font.family: S.Style.fontFamilyMono
					}
				}
			}

			// empty placeholder
			Text {
				anchors.centerIn: parent
				visible: root._listCount === 0
				text: "No waypoints"
				color: S.Style.textMuted
				font.pixelSize: 11
				font.family: S.Style.fontFamily
			}
		}
	}
}
