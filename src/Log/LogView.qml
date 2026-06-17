pragma ComponentBehavior: Bound

import Agc.Log
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
	id: root

	property string boundSource: ""
	property bool   pinned: false

	property bool showHeader:       true
	property bool showSourceFilter: true
	property bool showLevelFilter:  true
	property bool showSearch:       true
	property bool showDetach:       false
	property bool showAttach:       false

	readonly property bool inPinnedMode: pinned && boundSource.length > 0

	signal detachRequested()
	signal attachRequested()

	LogFilterModel {
		id: proxy
		sourceModel: LogManager.model
	}

	function _applyFilters() {
		if (!proxy) return;
		proxy.minLevel = levelCombo.currentIndex;
		proxy.search = searchField.text;
		if (root.inPinnedMode) {
			proxy.sourceFilter = [root.boundSource];
		} else if (srcCombo.currentValue === "*" || srcCombo.currentValue === undefined) {
			proxy.sourceFilter = [];
		} else {
			proxy.sourceFilter = [srcCombo.currentValue];
		}
	}

	Component.onCompleted: _applyFilters()
	onBoundSourceChanged: _applyFilters()
	onPinnedChanged: _applyFilters()

	Rectangle {
		anchors.fill: parent
		color: "#ffffff"

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 8
			spacing: 6

			RowLayout {
				Layout.fillWidth: true
				spacing: 6

				ComboBox {
					id: srcCombo
					visible: root.showSourceFilter && !root.inPinnedMode
					Layout.preferredWidth: 180
					textRole: "label"
					valueRole: "value"
					model: {
						const arr = [{ "label": qsTr("All sources"), "value": "*" }];
						const srcs = LogManager.sources;
						const seen = {};
						for (let i = 0; i < srcs.length; ++i) {
							const s = srcs[i];
							if (seen[s]) continue;
							seen[s] = true;
							arr.push({ "label": s, "value": s });
						}
						return arr;
					}
					onCurrentValueChanged: root._applyFilters()
				}

				ComboBox {
					id: levelCombo
					visible: root.showLevelFilter
					Layout.preferredWidth: 110
					model: ["Debug", "Info", "Warning", "Error", "Critical"]
					currentIndex: 1
					onCurrentIndexChanged: root._applyFilters()
				}

				TextField {
					id: searchField
					visible: root.showSearch
					Layout.fillWidth: true
					placeholderText: qsTr("Search…")
					color: "#2a3038"
					placeholderTextColor: "#a0a8b0"
					background: Rectangle {
						color: "#f6f7f9"
						border.color: "#d8dde2"
						radius: 2
					}
					onTextChanged: root._applyFilters()
				}

				Button {
					visible: root.showDetach
					text: qsTr("↗ Detach")
					onClicked: root.detachRequested()
					ToolTip.visible: hovered
					ToolTip.text: qsTr("Show this log in the master panel (all sources)")
				}
				Button {
					visible: root.showAttach
					text: qsTr("⤓ Re-attach")
					onClicked: root.attachRequested()
					ToolTip.visible: hovered
					ToolTip.text: qsTr("Return this log to the drone panel")
				}
			}

			Rectangle {
				Layout.fillWidth: true
				Layout.fillHeight: true
				color: "#fafbfc"
				border.color: "#e8e8ec"

				ListView {
					id: list
					anchors.fill: parent
					anchors.margins: 1
					clip: true
					model: proxy
					reuseItems: true
					cacheBuffer: 400
					boundsBehavior: Flickable.StopAtBounds

					property bool stickToBottom: true
					onMovementStarted: stickToBottom = false
					onAtYEndChanged: if (atYEnd) stickToBottom = true

					Connections {
						target: proxy
						function onRowsInserted() {
							if (list.stickToBottom)
								Qt.callLater(list.positionViewAtEnd)
						}
					}

					delegate: Item {
						id: rowItem
						required property string timestamp
						required property string source
						required property string message
						required property string levelName
						required property int level

						width: ListView.view ? ListView.view.width : 0
						implicitHeight: rowText.implicitHeight + 4

						Rectangle {
							anchors.fill: parent
							color: (rowItem.level >= 3) ? "#ffe8e0"
							     : (rowItem.level === 2) ? "#fff5d6"
							     : "transparent"
						}

						RowLayout {
							anchors.fill: parent
							anchors.leftMargin: 6
							anchors.rightMargin: 6
							spacing: 8

							Text {
								text: rowItem.timestamp
								color: "#9098a4"
								font.pixelSize: 11
								font.family: "Consolas, Menlo, monospace"
							}
							Text {
								Layout.preferredWidth: 72
								text: "[" + rowItem.source + "]"
								color: "#2a5080"
								font.pixelSize: 11
								font.bold: true
								font.family: "Consolas, Menlo, monospace"
								elide: Text.ElideRight
							}
							Text {
								Layout.preferredWidth: 60
								text: rowItem.levelName
								color: rowItem.level >= 3 ? "#8a2010"
								     : rowItem.level === 2 ? "#7a5a00"
								     : rowItem.level === 1 ? "#4a5060"
								     : "#9098a4"
								font.pixelSize: 11
								font.family: "Consolas, Menlo, monospace"
							}
							Text {
								id: rowText
								Layout.fillWidth: true
								text: rowItem.message
								color: rowItem.level >= 3 ? "#8a2010"
								     : rowItem.level === 2 ? "#7a5a00"
								     : "#2a3038"
								font.pixelSize: 11
								font.family: "Consolas, Menlo, monospace"
								wrapMode: Text.NoWrap
								elide: Text.ElideRight
							}
						}
					}

					ScrollBar.vertical: ScrollBar {}
				}
			}

			RowLayout {
				Layout.fillWidth: true
				spacing: 6
				Text {
					id: counter
					property int shown: 0
					property int total: 0
					text: qsTr("%1 / %2 lines").arg(shown).arg(total)
					color: "#9098a4"
					font.pixelSize: 10
					font.family: "Segoe UI"
					Connections {
						target: proxy
						function onRowsInserted() { counter.shown = proxy.rowCount() }
						function onRowsRemoved()  { counter.shown = proxy.rowCount() }
						function onModelReset()   { counter.shown = proxy.rowCount() }
						function onLayoutChanged(){ counter.shown = proxy.rowCount() }
					}
					Connections {
						target: LogManager.model
						function onRowsInserted() { counter.total = LogManager.model.rowCount() }
						function onRowsRemoved()  { counter.total = LogManager.model.rowCount() }
						function onModelReset()   { counter.total = LogManager.model.rowCount() }
					}
				}
				Item { Layout.fillWidth: true }
				CheckBox {
					id: tailToggle
					text: qsTr("Auto-scroll")
					checked: list.stickToBottom
					onToggled: list.stickToBottom = checked
					contentItem: Text {
						text: tailToggle.text
						color: "#4a5060"
						font.pixelSize: 11
						leftPadding: tailToggle.indicator.width + 4
						verticalAlignment: Text.AlignVCenter
					}
				}
			}
		}
	}
}
