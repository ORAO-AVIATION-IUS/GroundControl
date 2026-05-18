import QtQuick
import QtQuick.Layouts

Item {
	id: root

	property real pitch: 0.0
	property real roll: 0.0
	property real heading: 0.0

	GridLayout {
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.margins: 10
		columns: 3
		rowSpacing: 6
		columnSpacing: 6

		AttitudeIndicator {
			Layout.fillWidth: true
			Layout.preferredHeight: width
			pitch: root.pitch
			roll: root.roll
		}
		CompassIndicator {
			Layout.fillWidth: true
			Layout.preferredHeight: width
			heading: root.heading
		}
		HeadingIndicator {
			Layout.fillWidth: true
			Layout.preferredHeight: width
			heading: root.heading
		}
	}
}
