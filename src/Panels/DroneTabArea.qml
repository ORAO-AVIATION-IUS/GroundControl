pragma ComponentBehavior: Bound

import Agc.Camera
import Agc.Log
import Agc.Mavlink
import Agc.Style as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// DroneTabArea - the tabbed Log / Cameras region of the drone panel.
//
// A tab bar (always visible) sits above the content. The "Log" tab plus one tab
// per camera assigned to this drone. Each tab is detachable: detaching shows the
// corresponding free-floating KDDW dock and the tab switches to a "Re-attach ✕"
// chip. Because a camera stream's video sink can feed only one VideoOutput, the
// inline stream is only instantiated while its standalone dock is closed and this
// panel is the primary one for the drone.
Item {
	id: root

	property DroneManager drone: null
	property var cameraModel: null
	property var cameraDocks: null
	// This drone's per-drone Log dock (KDDW DockWidget) used when the Log tab is
	// detached. May be null until docks are created.
	property var logDock: null
	// Only the primary panel for a drone renders inline camera streams (avoids two
	// VideoOutputs fighting over a single sink).
	property bool panelIsPrimary: true
	// True while the owning drone panel dock is open/visible.
	property bool panelOpen: true

	// "log" or "cam:<cameraId>"
	property string currentTab: "log"

	readonly property bool logDetached: logDock ? logDock.isOpen : false

	function _selectCam(id) {
		currentTab = "cam:" + id;
	}

	// ── A single tab in the bar. Doubles as a "re-attach" chip when detached. ──
	component TabChip: Rectangle {
		id: chip

		property string label: ""
		property bool active: false
		property bool detached: false
		signal selected
		signal detachRequested
		signal reattachRequested

		Layout.fillHeight: true
		implicitWidth: chipRow.implicitWidth + 18
		color: chip.active && !chip.detached ? S.Style.bgPanel : tabMa.containsMouse ? S.Style.bgHover : "transparent"

		// Base click area (select when attached, re-attach when detached).
		// Declared first so it sits *below* the per-icon MouseAreas below.
		MouseArea {
			id: tabMa
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: {
				if (chip.detached)
					chip.reattachRequested();
				else
					chip.selected();
			}
		}

		// active-tab accent underline
		Rectangle {
			anchors.bottom: parent.bottom
			width: parent.width
			height: 2
			visible: chip.active && !chip.detached
			color: S.Style.info
		}

		RowLayout {
			id: chipRow
			anchors.centerIn: parent
			spacing: 5

			Text {
				visible: chip.detached
				text: "⤓"
				color: S.Style.warning
				font.pixelSize: 12
				font.family: S.Style.fontFamily
			}
			Text {
				text: chip.label
				color: chip.detached ? S.Style.warning : chip.active ? S.Style.textPrimary : S.Style.textSecondary
				font.pixelSize: 11
				font.bold: chip.active || chip.detached
				font.family: S.Style.fontFamily
			}
			// detach affordance (only on the active, attached tab) — its own
			// MouseArea sits above tabMa so it wins clicks on the icon.
			Text {
				visible: chip.active && !chip.detached
				text: "↗"
				color: detachMa.containsMouse ? S.Style.textPrimary : S.Style.textMuted
				font.pixelSize: 13
				font.bold: true
				font.family: S.Style.fontFamily
				MouseArea {
					id: detachMa
					anchors.fill: parent
					anchors.margins: -5
					cursorShape: Qt.PointingHandCursor
					onClicked: chip.detachRequested()
					hoverEnabled: true
					ToolTip.visible: containsMouse
					ToolTip.text: qsTr("Detach into its own window")
				}
			}
			// re-attach close (only when detached)
			Text {
				visible: chip.detached
				text: "✕"
				color: S.Style.textMuted
				font.pixelSize: 12
				font.family: S.Style.fontFamily
			}
		}
	}

	// ── A placeholder shown in the content area when a tab is detached. ──
	component DetachedNote: ColumnLayout {
		id: note
		property string label: ""
		signal reattach
		spacing: 8
		Item {
			Layout.fillHeight: true
		}
		Text {
			Layout.alignment: Qt.AlignHCenter
			text: qsTr("%1 is shown in its own window").arg(note.label)
			color: S.Style.textSecondary
			font.pixelSize: 12
			font.family: S.Style.fontFamily
		}
		Button {
			Layout.alignment: Qt.AlignHCenter
			text: qsTr("⤓ Re-attach")
			onClicked: note.reattach()
		}
		Item {
			Layout.fillHeight: true
		}
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: 0

		// ── Tab bar ──
		Rectangle {
			Layout.fillWidth: true
			Layout.preferredHeight: 30
			color: S.Style.bgSection

			RowLayout {
				anchors.fill: parent
				spacing: 0

				TabChip {
					label: qsTr("LOG")
					active: root.currentTab === "log"
					detached: root.logDetached
					onSelected: root.currentTab = "log"
					onDetachRequested: {
						if (root.logDock) {
							root.logDock.show();
							root.currentTab = "log";
						}
					}
					onReattachRequested: if (root.logDock)
						root.logDock.close()
				}

				Repeater {
					model: root.cameraModel
					delegate: TabChip {
						id: camChip
						required property int index
						required property var model

						readonly property var dock: (root.cameraDocks && root.cameraDocks.count > index) ? root.cameraDocks.itemAt(index) : null

						visible: root.drone && model.droneUid === root.drone.droneUid
						// collapse hidden chips so they take no space
						Layout.preferredWidth: visible ? implicitWidth : 0

						label: model.name
						active: root.currentTab === ("cam:" + model.cameraId)
						detached: camChip.dock ? camChip.dock.isOpen : false

						onSelected: root._selectCam(model.cameraId)
						onDetachRequested: {
							if (camChip.dock) {
								camChip.dock.show();
								root.currentTab = "log";
							}
						}
						onReattachRequested: {
							if (camChip.dock) {
								camChip.dock.close();
								root._selectCam(model.cameraId);
							}
						}
					}
				}

				Item {
					Layout.fillWidth: true
				}
			}
		}

		Rectangle {
			Layout.fillWidth: true
			Layout.preferredHeight: 1
			color: S.Style.separator
		}

		// ── Content area ──
		Item {
			Layout.fillWidth: true
			Layout.fillHeight: true

			// Log (inline)
			LogView {
				anchors.fill: parent
				visible: root.currentTab === "log" && !root.logDetached
				boundSource: root.drone ? root.drone.droneName : ""
				pinned: true
				showAttach: false
				showDetach: false
			}

			// Log (detached note)
			DetachedNote {
				anchors.fill: parent
				visible: root.currentTab === "log" && root.logDetached
				label: qsTr("Log")
				onReattach: if (root.logDock)
					root.logDock.close()
			}

			// Camera contents
			Repeater {
				model: root.cameraModel
				delegate: Item {
					id: camContent
					required property int index
					required property var model

					readonly property var dock: (root.cameraDocks && root.cameraDocks.count > index) ? root.cameraDocks.itemAt(index) : null
					readonly property bool detached: camContent.dock ? camContent.dock.isOpen : false
					readonly property bool isThis: root.currentTab === ("cam:" + model.cameraId) && root.drone && model.droneUid === root.drone.droneUid

					anchors.fill: parent
					visible: camContent.isThis

					// If this camera gets detached elsewhere (e.g. opened from the
					// menu) while selected, fall back to the Log tab.
					onDetachedChanged: if (detached && isThis)
						root.currentTab = "log"

					Rectangle {
						anchors.fill: parent
						color: "#14141e"
						visible: !camContent.detached
					}

					// inline stream — only while attached, primary, and visible
					Loader {
						anchors.fill: parent
						active: camContent.visible && !camContent.detached && root.panelIsPrimary && root.panelOpen
						sourceComponent: CameraStream {
							streamId: camContent.model.cameraId
						}
					}

					// shown elsewhere because another panel is primary for this drone
					Text {
						anchors.centerIn: parent
						visible: !camContent.detached && !root.panelIsPrimary
						text: qsTr("Shown in the selected-drone panel")
						color: S.Style.textMuted
						font.pixelSize: 12
						font.family: S.Style.fontFamily
					}

					DetachedNote {
						anchors.fill: parent
						visible: camContent.detached
						label: camContent.model.name
						onReattach: if (camContent.dock)
							camContent.dock.close()
					}
				}
			}
		}
	}
}
