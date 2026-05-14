import Agc.Style
import QtQuick
import QtQuick.Controls

AbstractButton {
	id: root

	property string iconName: ""
	property string iconSource: ""
	property string label: ""
	property color labelColor: Style.iconBtnLabelColor
	property int labelSize: Style.iconBtnLabelSize
	property bool highlighted: false

	// Mirror checkable/checked from AbstractButton
	// checkable and checked are already provided by AbstractButton

	hoverEnabled: true

	implicitWidth: Math.max(iconImage.width, labelText.implicitWidth) + Style.iconBtnPadding * 2
	implicitHeight: iconImage.height + (labelText.visible ? labelText.implicitHeight + 2 : 0) + Style.iconBtnPadding * 2

	background: Rectangle {
		radius: Style.iconBtnRadius
		color: {
			if (!root.enabled)
				return "transparent";
			if (root.pressed)
				return Style.iconBtnPressedBg;
			if (root.checked)
				return Style.iconBtnCheckedBg;
			if (root.highlighted)
				return Style.iconBtnHighlightBg;
			if (root.hovered)
				return Style.iconBtnHoverBg;
			return "transparent";
		}
		Behavior on color {
			ColorAnimation {
				duration: 120
			}
		}
	}

	contentItem: Item {
		opacity: root.enabled ? 1.0 : 0.3
		Behavior on opacity {
			NumberAnimation {
				duration: 150
			}
		}

		Image {
			id: iconImage
			anchors.top: parent.top
			anchors.topMargin: Style.iconBtnPadding
			anchors.horizontalCenter: parent.horizontalCenter
			width: Style.iconBtnSize
			height: Style.iconBtnSize
			fillMode: Image.PreserveAspectFit
			source: root.iconName !== "" ? "image://icon/" + root.iconName : root.iconSource
			opacity: root.pressed ? 0.6 : root.hovered ? 1.0 : 0.85
			Behavior on opacity {
				NumberAnimation {
					duration: 120
				}
			}
		}

		Text {
			id: labelText
			anchors.top: iconImage.bottom
			anchors.topMargin: 2
			anchors.bottom: parent.bottom
			anchors.bottomMargin: Style.iconBtnPadding
			anchors.horizontalCenter: parent.horizontalCenter
			text: root.label
			color: root.checked ? Style.iconBtnCheckedLabelColor : root.labelColor
			font.pixelSize: root.labelSize
			visible: root.label !== ""
		}
	}
}
