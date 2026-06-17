pragma ComponentBehavior: Bound

import Agc.Style as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// MissionWaypointList - shows the active mission plan as a waypoint list,
// highlighting the waypoint the drone is currently flying to, the plan
// completion progress, and start / pause controls.
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
	property bool uploaded: false
	property bool dirty: false
	property bool busy: false
	property bool connected: false
	property bool readyToFly: false
	property string busyText: ""
	property string errorText: ""

	signal startClicked
	signal pauseClicked

	readonly property int _listCount: root.items ? root.items.length : 0
	readonly property int _total: root.totalWp > 0 ? root.totalWp : root._listCount
	readonly property int _done: root.running || root.paused ? Math.max(0, Math.min(root.currentWp, root._total)) : 0
	readonly property real _progress: root._total > 0 ? root._done / root._total : 0

	function _cmdLabel(modelData, index) {
		const cmd = modelData && modelData.command ? modelData.command : "waypoint";
		if (cmd === "takeoff")
			return "TAKEOFF";
		if (cmd === "land")
			return "LAND";
		return "WP " + (index + 1);
	}

	component ActBtn: Rectangle {
		id: actBtn

		property string label: ""
		property color accent: S.Style.info
		signal tapped

		Layout.fillWidth: true
		Layout.preferredHeight: 28
		radius: 0
		color: !enabled ? Qt.darker(S.Style.controlActionBg, 0.92) : ma.pressed ? Qt.darker(actBtn.accent, 2.4) : ma.containsMouse ? Qt.darker(actBtn.accent, 2.8) : S.Style.controlActionBg
		border.color: actBtn.enabled ? actBtn.accent : S.Style.borderDefault
		border.width: 1
		opacity: enabled ? 1.0 : 0.4

		Text {
			anchors.centerIn: parent
			text: actBtn.label
			color: actBtn.enabled ? actBtn.accent : S.Style.textMuted
			font.pixelSize: 11
			font.bold: true
			font.family: S.Style.fontFamily
		}

		MouseArea {
			id: ma
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: actBtn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
			onClicked: if (actBtn.enabled)
				parent.tapped()
		}
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

		// ── Progress bar ──
		Rectangle {
			Layout.fillWidth: true
			Layout.topMargin: 8
			Layout.preferredHeight: 4
			radius: 2
			color: S.Style.bgElevated

			Rectangle {
				width: parent.width * root._progress
				height: parent.height
				radius: 2
				color: root.running ? S.Style.info : root.paused ? S.Style.warning : S.Style.success
				Behavior on width {
					NumberAnimation {
						duration: 250
						easing.type: Easing.OutCubic
					}
				}
			}
		}

		// ── Status line ──
		Text {
			Layout.fillWidth: true
			Layout.topMargin: 5
			text: {
				if (root.busy && root.busyText !== "")
					return root.busyText;
				if (root.errorText !== "")
					return root.errorText;
				if (root._listCount === 0)
					return "No mission planned";
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

		// ── Start / Pause (only the relevant one) ──
		RowLayout {
			Layout.fillWidth: true
			Layout.topMargin: 8
			spacing: 6
			visible: root._listCount > 0

			ActBtn {
				label: root.paused ? "RESUME" : "START"
				accent: S.Style.success
				visible: !root.running
				enabled: root.connected && root.readyToFly && root.uploaded && !root.dirty && !root.busy
				onTapped: root.startClicked()
			}
			ActBtn {
				label: "PAUSE"
				accent: S.Style.warning
				visible: root.running
				enabled: !root.busy
				onTapped: root.pauseClicked()
			}
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
			spacing: 1
			boundsBehavior: Flickable.StopAtBounds

			ScrollBar.vertical: ScrollBar {
				policy: ScrollBar.AsNeeded
			}

			delegate: Rectangle {
				id: wpRow

				required property int index
				required property var modelData

				readonly property bool isCurrent: (root.running || root.paused) && root.currentWp === wpRow.index
				readonly property bool isDone: (root.running || root.paused) && wpRow.index < root.currentWp

				width: ListView.view ? ListView.view.width : 0
				height: 30
				color: wpRow.isCurrent ? Qt.rgba(0.12, 0.43, 0.92, 0.16) : "transparent"

				Rectangle {
					anchors.left: parent.left
					width: 2
					height: parent.height
					color: wpRow.isCurrent ? S.Style.info : "transparent"
				}

				RowLayout {
					anchors.fill: parent
					anchors.leftMargin: 8
					anchors.rightMargin: 4
					spacing: 8

					// state marker
					Item {
						Layout.preferredWidth: 16
						Layout.preferredHeight: 16

						// done check
						Text {
							anchors.centerIn: parent
							visible: wpRow.isDone
							text: "✓"
							color: S.Style.success
							font.pixelSize: 12
							font.bold: true
						}
						// current / pending dot
						Rectangle {
							anchors.centerIn: parent
							visible: !wpRow.isDone
							width: wpRow.isCurrent ? 9 : 6
							height: width
							radius: width / 2
							color: wpRow.isCurrent ? S.Style.info : S.Style.textMuted
						}
					}

					Text {
						text: root._cmdLabel(wpRow.modelData, wpRow.index)
						color: wpRow.isCurrent ? S.Style.textPrimary : wpRow.isDone ? S.Style.textMuted : S.Style.textSecondary
						font.pixelSize: 11
						font.bold: wpRow.isCurrent
						font.family: S.Style.fontFamily
						Layout.fillWidth: true
						elide: Text.ElideRight
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
